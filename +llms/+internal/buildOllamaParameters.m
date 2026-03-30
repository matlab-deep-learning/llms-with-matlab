function parameters = buildOllamaParameters(model, messages, functions, nvp)
%buildOllamaParameters Build parameters struct for Ollama Chat API
%
%   PARAMETERS = buildOllamaParameters(MODEL, MESSAGES, FUNCTIONS, NVP) builds a
%   struct in the format expected by the Ollama Chat API, combining MODEL,
%   MESSAGES, FUNCTIONS and parameters in NVP.
%
%   NVP is a struct with fields: Temperature, TopP, MinP, TopK,
%   TailFreeSamplingZ, StopSequences, MaxNumTokens, ResponseFormat, Seed, StreamFun.
%
%   See also: llms.internal.callOllamaChatAPI

%   Copyright 2023-2026 The MathWorks, Inc.

parameters = struct();
parameters.model = model;
parameters.messages = messages;

parameters.stream = ~isempty(nvp.StreamFun);

if ~isempty(functions)
    parameters.tools = functions;
end

options = struct;

if strcmp(nvp.ResponseFormat,"json")
    parameters.format = "json";
elseif isstruct(nvp.ResponseFormat)
    parameters.format = llms.internal.jsonSchemaFromPrototype(nvp.ResponseFormat);
elseif startsWith(string(nvp.ResponseFormat), asManyOfPattern(whitespacePattern)+"{")
    parameters.format = llms.internal.verbatimJSON(nvp.ResponseFormat);
end

if ~isempty(nvp.Seed)
    options.seed = nvp.Seed;
end

dict = mapNVPToParameters();

nvpOptions = keys(dict);
for opt = nvpOptions.'
    if isfield(nvp, opt) && ~isempty(nvp.(opt)) && ~isequaln(nvp.(opt),Inf) && ~isequal(nvp.(opt), "auto")
        options.(dict(opt)) = nvp.(opt);
    end
end

parameters.options = options;
end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopP") = "top_p";
dict("MinP") = "min_p";
dict("TopK") = "top_k";
dict("TailFreeSamplingZ") = "tfs_z";
dict("StopSequences") = "stop";
dict("MaxNumTokens") = "num_predict";
end
