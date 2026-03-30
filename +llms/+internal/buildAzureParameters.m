function parameters = buildAzureParameters(messages, functions, nvp)
%buildAzureParameters Build parameters struct for Azure OpenAI Chat API
%
%   PARAMETERS = buildAzureParameters(MESSAGES, FUNCTIONS, NVP) builds a
%   struct in the format expected by the Azure OpenAI Chat Completions API,
%   combining MESSAGES, FUNCTIONS and parameters in NVP.
%
%   NVP is a struct with fields: ToolChoice, Temperature, TopP,
%   NumCompletions, StopSequences, MaxNumTokens, PresencePenalty,
%   FrequencyPenalty, ResponseFormat, Seed, StreamFun.
%
%   See also: llms.internal.callAzureChatAPI

%   Copyright 2023-2026 The MathWorks, Inc.

parameters = struct();
parameters.messages = messages;

parameters.stream = ~isempty(nvp.StreamFun);

if ~isempty(functions)
    parameters.tools = functions;
end

if ~isempty(nvp.ToolChoice)
    parameters.tool_choice = nvp.ToolChoice;
end

if strcmp(nvp.ResponseFormat,"json")
    parameters.response_format = struct('type','json_object');
elseif isstruct(nvp.ResponseFormat)
    parameters.response_format = struct('type','json_schema',...
        'json_schema', struct('strict', true, 'name', 'computedFromPrototype', ...
            'schema', llms.internal.jsonSchemaFromPrototype(nvp.ResponseFormat)));
elseif startsWith(string(nvp.ResponseFormat), asManyOfPattern(whitespacePattern)+"{")
    parameters.response_format = struct('type','json_schema',...
        'json_schema', struct('strict', true, 'name', 'providedInCall', ...
            'schema', llms.internal.verbatimJSON(nvp.ResponseFormat)));
end

if ~isempty(nvp.Seed)
    parameters.seed = nvp.Seed;
end

dict = mapNVPToParameters();

nvpOptions = keys(dict);
for opt = nvpOptions.'
    if isfield(nvp, opt) && ~isempty(nvp.(opt)) && ~isequal(nvp.(opt), "auto")
        parameters.(dict(opt)) = nvp.(opt);
    end
end

if nvp.MaxNumTokens == Inf
    parameters = rmfield(parameters,dict("MaxNumTokens"));
end

if nvp.Verbosity ~= "auto"
    parameters.verbosity = nvp.Verbosity;
end

if nvp.ReasoningEffort ~= "auto"
    parameters.reasoning_effort = nvp.ReasoningEffort;
end

end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopP") = "top_p";
dict("NumCompletions") = "n";
dict("StopSequences") = "stop";
dict("MaxNumTokens") = "max_completion_tokens";
dict("PresencePenalty") = "presence_penalty";
dict("FrequencyPenalty") = "frequency_penalty";
end
