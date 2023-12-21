function [emb, response] = extractOpenAIEmbeddings(text, nvp)
% EXTRACTOPENAIEMBEDDINGS  Generate text embeddings using the OpenAI API
%
%   emb = EXTRACTOPENAIEMBEDDINGS(text) generates an embedding of the input
%   TEXT using the OpenAI API.
%
%   emb = EXTRACTOPENAIEMBEDDINGS(text,Name=Value) specifies optional
%   specifies additional options using one or more name-value pairs:
%
%   'ModelName'                 - The ID of the model to use.
%
%   'ApiKey'                    - OpenAI API token. It can also be specified by
%                                setting the environment variable OPENAI_API_KEY
%
%   'TimeOut'                   - Connection Timeout in seconds (default: 10 secs)
%
%   [emb, response] = EXTRACTOPENAIEMBEDDINGS(...) also returns the full
%   response from the OpenAI API call.
%
%   Copyright 2023 The MathWorks, Inc.

arguments
    text          (1,:) {mustBeText}
    nvp.ModelName (1,1) {mustBeMember(nvp.ModelName,"text-embedding-ada-002")} = "text-embedding-ada-002"
    nvp.TimeOut   (1,1) {mustBeReal,mustBePositive} = 10
    nvp.ApiKey          {llms.utils.mustBeNonzeroLengthTextScalar}
end

END_POINT = "https://api.openai.com/v1/embeddings";

key = llms.internal.getApiKeyFromNvpOrEnv(nvp);

parameters = struct("input",text,"model",nvp.ModelName);

response = llms.internal.sendRequest(parameters,key, END_POINT, nvp.TimeOut);

if isfield(response, "data")
    emb = [response.Body.Data.data.embedding];
    emb = emb';
else
    emb = [];
end