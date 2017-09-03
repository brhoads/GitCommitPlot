function [commit, branch] = gimwrite( varargin )
%GIMWRITE Extends imwrite to add git commit to image metadata
%   GIMWRITE(FILENAME) writes the current figure to FILENAME
%   GIMWRITE(FILENAME,A) writes the image A to FILENAME
%   GIMWRITE(FILENAME,F) writes figure F to FILENAME
%
%   GIMWRITE is a wrapper function around imwrite that is capable of adding
%   git commit hashes to the metadata of the written image. 
%
%   

% Input parser to filter gimwrite flags from imwrite flags
p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'Filename') 
addOptional(p,'Object','')
addParameter(p,'RepoDir','')
addParameter(p,'Comment','') % Force arg so two are sent to imwrite
addParameter(p,'Commit',false,@boolean)
parse(p,varargin{:})

% Check to see if an object was passed through, if there was, check to see
% if it was a figure handle
if isa(p.Results.Object,'uint8')
    % Argument is an image
    image = p.Results.Object;
else
    % Argument is empty or a fig
    if isgraphics(p.Results.Object)
        fig = p.Results.Object;
    else
        fig = gcf;
    end
    % Grab the image from the fig
    fig.Color = 'w'; % Change from default grey background
    image = frame2im(getframe(fig));
end

% Get the git things
import org.eclipse.jgit.api.Git
if isempty(p.Results.RepoDir);
    dir = fullfile(pwd,'.git');
elseif isempty(strfind(p.Results.RepoDir,'.git'))
    warning('RepoDir does not contain ''.git''')
    dir = p.Results.RepoDir;
else
    dir = p.Results.RepoDir;
end

% methodsview('org.eclipse.jgit.api.Git')
% methodsview('org.eclipse.jgit.lib.Repository')
% methodsview('org.eclipse.jgit.lib.Ref')
try
    file = java.io.File(fullfile(dir));
    git = Git.open(file);
catch
    error('Could not find git repo. Consider using ''RepoDir'' argument');
end
repo = git.getRepository();
commit = cell(repo.getRef('HEAD').getObjectId.name);

% Convert imwrite passthrough arguments from struct to arg list
if ~isempty(fieldnames(p.Unmatched))
    % Convert the unmatched args to a 'Key','Value,'Pair','String'
    imwriteArgs = {fieldnames(p.Unmatched), struct2cell(p.Unmatched)};
    imwriteArgs = reshape(horzcat(imwriteArgs{:})',1,[]);
else
    imwriteArgs = {};
end

% Append metadata to imwriteArgs
imwriteArgs = [imwriteArgs, 'Comment', commit];

% Write the image
imwrite(image, p.Results.Filename, imwriteArgs{:})

branch = '';

end

