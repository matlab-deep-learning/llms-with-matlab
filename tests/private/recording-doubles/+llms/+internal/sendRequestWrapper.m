function [response, streamedText] = sendRequestWrapper(parameters, token, varargin)
% This function is undocumented and will change in a future release

% A wrapper around sendRequest to have a test seam
persistent seenCalls
if isempty(seenCalls)
    seenCalls = cell(0,2);
end

persistent filename

if nargin == 1 && isequal(parameters,"close")
    save(filename+".mat","seenCalls");
    seenCalls = cell(0,2);
    return
end

if nargin==2 && isequal(parameters,"open")
    filename = token;
    return
end

streamFunCalls = {};
hasCallback = nargin >= 5 && isa(varargin{3},'function_handle');
if hasCallback
    streamFun = varargin{3};
end
function wrappedStreamFun(varargin)
    streamFunCalls(end+1) = varargin;
    streamFun(varargin{:});
end
if hasCallback
    varargin{3} = @wrappedStreamFun;
end


[response, streamedText] = llms.internal.sendRequest(parameters, token, varargin{:});

seenCalls(end+1,:) = {{parameters},{response,streamFunCalls,streamedText}};
end
