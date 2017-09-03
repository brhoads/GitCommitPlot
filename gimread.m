function [X, map, alpha, commit] = gimread(varargin)
%GIMREAD Extends imread to checkout the git commit in the image metadata
%   GIMREAD(FILENAME) read the image specified by FILENAME
%
%   GIMREAD is a wrapper function around imread that will checkout the git
%   commit specified in the 'Comment' field of the image metadata
%
% 

% Input parser to filter gimread flags from imread flags
p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'Filename')
addParameter(p,'RepoDir','')
addParameter(p,'Stash',false,@boolean)
parse(p,varargin{:})


% Convert imread passthrough arguments from struct to arg list
if ~isempty(fieldnames(p.Unmatched))
    % Convert the unmatched args to a 'Key','Value,'Pair','String'
    imreadArgs = {fieldnames(p.Unmatched), struct2cell(p.Unmatched)};
    imreadArgs = reshape(horzcat(imreadArgs{:})',1,[]);
else
    imreadArgs = {};
end

% Read the image
[X,map,alpha] = imread(p.Results.Filename, imreadArgs{:});

% Check for git commit in metadata
info = imfinfo(p.Results.Filename);

if isempty(info.Comment)
    warning('Image does not contain git commit information.')
    return
else
    commit = info.Comment;
    disp(info.Comment)
end

% Check for git repo in args & open
import org.eclipse.jgit.api.Git
if isempty(p.Results.RepoDir);
    dir = fullfile(pwd,'/.git');
elseif isempty(strfind(p.Results.RepoDir,'.git'))
    warning('RepoDir does not contain ''.git''')
    dir = p.Results.RepoDir;
else
    dir = p.Results.RepoDir;
end
% Attempt to open repo
try
    file = java.io.File(fullfile(dir));
    git = Git.open(file);
catch
    error('Could not find git repo: %s.\nConsider using ''RepoDir'' argument', char(file.toString));
end

git.checkout().setName(commit).call()
