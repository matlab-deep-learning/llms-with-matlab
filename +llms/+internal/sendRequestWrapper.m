function [response, streamedText] = sendRequestWrapper(varargin)
% This function is undocumented and will change in a future release

% A wrapper around sendRequest to have a test seam
[response, streamedText] = llms.internal.sendRequest(varargin{:});
