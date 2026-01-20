function parameters = buildAnthropicParameters(messages, functions, nvp)
%buildAnthropicParameters Build parameters struct for Anthropic Messages API
%
%   PARAMETERS = buildAnthropicParameters(MESSAGES, FUNCTIONS, NVP) builds a
%   struct in the format expected by the Anthropic Messages API,
%   combining MESSAGES, FUNCTIONS and parameters in NVP.
%
%   NVP is a struct with fields: ModelName, Temperature, TopP,
%   StopSequences, MaxNumTokens, ResponseFormat, StreamFun, SystemPrompt,
%   ToolChoice.
%
%   Note: Anthropic API differences from OpenAI:
%   - System prompt is a separate top-level parameter, not in messages
%   - max_tokens is REQUIRED (not optional)
%   - No presence_penalty/frequency_penalty support
%   - No num_completions (n) support
%
%   See also: llms.internal.callAnthropicChatAPI

%   Copyright 2025 The MathWorks, Inc.

parameters = struct();

% Model is required
parameters.model = nvp.ModelName;

% max_tokens is REQUIRED for Anthropic (unlike OpenAI where it's optional)
% Default to 4096 if not specified or if Inf
if ~isfield(nvp, 'MaxNumTokens') || isempty(nvp.MaxNumTokens) || nvp.MaxNumTokens == Inf
    parameters.max_tokens = 4096;
else
    parameters.max_tokens = nvp.MaxNumTokens;
end

% Extract system message from messages if present, or use SystemPrompt
systemContent = [];
userMessages = {};
for i = 1:numel(messages)
    msg = messages{i};
    if strcmp(msg.role, "system")
        systemContent = msg.content;
    else
        userMessages{end+1} = msg; %#ok<AGROW>
    end
end

% Use SystemPrompt from nvp if no system message was in messages
if isempty(systemContent) && isfield(nvp, 'SystemPrompt') && ~isempty(nvp.SystemPrompt)
    if iscell(nvp.SystemPrompt) && ~isempty(nvp.SystemPrompt)
        systemContent = nvp.SystemPrompt{1}.content;
    elseif ischar(nvp.SystemPrompt) || isstring(nvp.SystemPrompt)
        systemContent = nvp.SystemPrompt;
    end
end

if ~isempty(systemContent)
    parameters.system = systemContent;
end

% Set messages (without system messages)
if isempty(userMessages)
    parameters.messages = messages;
else
    parameters.messages = userMessages;
end

% Streaming
parameters.stream = ~isempty(nvp.StreamFun);

% Tools (function calling)
if ~isempty(functions)
    % Convert from OpenAI tool format to Anthropic format
    parameters.tools = convertToolsToAnthropic(functions);
end

% Tool choice
if isfield(nvp, 'ToolChoice') && ~isempty(nvp.ToolChoice)
    parameters.tool_choice = convertToolChoiceToAnthropic(nvp.ToolChoice);
end

% Map remaining parameters
dict = mapNVPToParameters();
nvpOptions = keys(dict);
for opt = nvpOptions.'
    if isfield(nvp, opt) && ~isempty(nvp.(opt))
        parameters.(dict(opt)) = nvp.(opt);
    end
end

end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopP") = "top_p";
dict("StopSequences") = "stop_sequences";
end

function anthropicTools = convertToolsToAnthropic(openAITools)
%convertToolsToAnthropic Convert OpenAI tool format to Anthropic format
%
%   OpenAI format:
%   {"type": "function", "function": {"name": "...", "description": "...", "parameters": {...}}}
%
%   Anthropic format:
%   {"name": "...", "description": "...", "input_schema": {...}}

anthropicTools = cell(size(openAITools));
for i = 1:numel(openAITools)
    tool = openAITools{i};
    if isfield(tool, 'function')
        fn = tool.function;
        anthropicTool = struct();
        anthropicTool.name = fn.name;
        if isfield(fn, 'description')
            anthropicTool.description = fn.description;
        end
        if isfield(fn, 'parameters')
            anthropicTool.input_schema = fn.parameters;
        else
            anthropicTool.input_schema = struct('type', 'object', 'properties', struct());
        end
        anthropicTools{i} = anthropicTool;
    else
        anthropicTools{i} = tool;
    end
end
end

function anthropicChoice = convertToolChoiceToAnthropic(toolChoice)
%convertToolChoiceToAnthropic Convert OpenAI tool_choice format to Anthropic format
%
%   OpenAI: "auto", "none", "required", or {"type": "function", "function": {"name": "..."}}
%   Anthropic: {"type": "auto"}, {"type": "any"}, {"type": "tool", "name": "..."}

if ischar(toolChoice) || isstring(toolChoice)
    switch toolChoice
        case "auto"
            anthropicChoice = struct('type', 'auto');
        case "none"
            % Anthropic doesn't have "none" - closest is not including tool_choice
            anthropicChoice = [];
        case "required"
            anthropicChoice = struct('type', 'any');
        otherwise
            % Assume it's a function name
            anthropicChoice = struct('type', 'tool', 'name', toolChoice);
    end
elseif isstruct(toolChoice) && isfield(toolChoice, 'function')
    % Convert from OpenAI struct format
    anthropicChoice = struct('type', 'tool', 'name', toolChoice.function.name);
else
    anthropicChoice = toolChoice;
end
end
