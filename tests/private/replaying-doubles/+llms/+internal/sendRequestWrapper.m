function [response, streamedText] = sendRequestWrapper(parameters, token, varargin)
% This function is undocumented and will change in a future release

% A wrapper around sendRequest to have a test seam
persistent seenCalls
if isempty(seenCalls)
    seenCalls = cell(0,2);
end

if nargin == 1 && isequal(parameters,"close")
    seenCalls = cell(0,2);
    return
end

if nargin==2 && isequal(parameters,"open")
    load(token+".mat","seenCalls");
    return
end

result = seenCalls{1,2};
response = result{1};
streamFunCalls = result{2};
streamedText = result{3};

if nargin >= 5 && isa(varargin{3},'function_handle')
    streamFun = varargin{3};
    cellfun(streamFun, streamFunCalls);
end

seenCalls(1,:) = [];
