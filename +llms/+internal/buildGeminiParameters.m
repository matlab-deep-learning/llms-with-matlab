function parameters = buildGeminiParameters(messages, functions, nvp)
%buildGeminiParameters Build parameters struct for Google Gemini API
%
%   PARAMETERS = buildGeminiParameters(MESSAGES, FUNCTIONS, NVP) builds a
%   struct in the format expected by the Google Gemini generateContent API,
%   combining MESSAGES, FUNCTIONS and parameters in NVP.
%
%   NVP is a struct with fields: ToolChoice, Temperature, TopP, TopK,
%   StopSequences, MaxNumTokens, ResponseFormat, StreamFun.
%
%   See also: llms.internal.callGeminiChatAPI

%   Copyright 2025 The MathWorks, Inc.

parameters = struct();

% Convert messages to Gemini format (contents with parts)
% Also extract system instruction if present
[contents, systemInstruction] = convertMessagesToGeminiFormat(messages);
parameters.contents = contents;

if ~isempty(systemInstruction)
    parameters.system_instruction = systemInstruction;
end

% Build generationConfig
generationConfig = struct();

if isfield(nvp, 'Temperature') && ~isempty(nvp.Temperature)
    generationConfig.temperature = nvp.Temperature;
end

if isfield(nvp, 'TopP') && ~isempty(nvp.TopP)
    generationConfig.topP = nvp.TopP;
end

if isfield(nvp, 'TopK') && ~isempty(nvp.TopK)
    generationConfig.topK = nvp.TopK;
end

if isfield(nvp, 'MaxNumTokens') && ~isempty(nvp.MaxNumTokens) && nvp.MaxNumTokens ~= Inf
    generationConfig.maxOutputTokens = nvp.MaxNumTokens;
end

if isfield(nvp, 'StopSequences') && ~isempty(nvp.StopSequences)
    generationConfig.stopSequences = nvp.StopSequences;
end

% Handle response format
if isfield(nvp, 'ResponseFormat') && ~isempty(nvp.ResponseFormat)
    if strcmp(nvp.ResponseFormat, "json")
        generationConfig.responseMimeType = "application/json";
    elseif isstruct(nvp.ResponseFormat)
        generationConfig.responseMimeType = "application/json";
        generationConfig.responseSchema = llms.internal.jsonSchemaFromPrototype(nvp.ResponseFormat);
    elseif startsWith(string(nvp.ResponseFormat), asManyOfPattern(whitespacePattern)+"{")
        generationConfig.responseMimeType = "application/json";
        generationConfig.responseSchema = llms.internal.verbatimJSON(nvp.ResponseFormat);
    end
end

if ~isempty(fieldnames(generationConfig))
    parameters.generationConfig = generationConfig;
end

% Convert tools to Gemini format
if ~isempty(functions)
    parameters.tools = convertToolsToGeminiFormat(functions);
end

% Handle tool choice
if isfield(nvp, 'ToolChoice') && ~isempty(nvp.ToolChoice)
    toolConfig = convertToolChoice(nvp.ToolChoice);
    if ~isempty(toolConfig)
        parameters.toolConfig = toolConfig;
    end
end

end

function [contents, systemInstruction] = convertMessagesToGeminiFormat(messages)
%convertMessagesToGeminiFormat Convert OpenAI-style messages to Gemini format
%
%   Gemini format:
%   contents: [
%     {"role": "user", "parts": [{"text": "..."}]},
%     {"role": "model", "parts": [{"text": "..."}]}
%   ]

contents = {};
systemInstruction = [];

for i = 1:numel(messages)
    msg = messages{i};

    if strcmp(msg.role, "system")
        % System instruction is separate in Gemini
        systemInstruction = struct('parts', {{struct('text', msg.content)}});
    elseif strcmp(msg.role, "user")
        geminiMsg = struct();
        geminiMsg.role = "user";
        geminiMsg.parts = convertContentToParts(msg);
        contents{end+1} = geminiMsg; %#ok<AGROW>
    elseif strcmp(msg.role, "assistant")
        geminiMsg = struct();
        geminiMsg.role = "model";

        % Handle tool calls in assistant message
        if isfield(msg, 'tool_calls') && ~isempty(msg.tool_calls)
            parts = {};
            if ~isempty(msg.content)
                parts{end+1} = struct('text', msg.content);
            end
            for j = 1:numel(msg.tool_calls)
                tc = msg.tool_calls(j);
                if isstruct(tc.function.arguments)
                    args = tc.function.arguments;
                else
                    args = jsondecode(tc.function.arguments);
                end
                functionCall = struct('name', tc.function.name, 'args', args);
                parts{end+1} = struct('functionCall', functionCall); %#ok<AGROW>
            end
            geminiMsg.parts = parts;
        else
            geminiMsg.parts = {{struct('text', msg.content)}};
        end
        contents{end+1} = geminiMsg; %#ok<AGROW>
    elseif strcmp(msg.role, "tool")
        % Tool response in Gemini format
        geminiMsg = struct();
        geminiMsg.role = "user";

        % Parse content if it's JSON
        if startsWith(msg.content, "{") || startsWith(msg.content, "[")
            try
                responseContent = jsondecode(msg.content);
            catch
                responseContent = struct('result', msg.content);
            end
        else
            responseContent = struct('result', msg.content);
        end

        functionResponse = struct('name', msg.name, 'response', responseContent);
        geminiMsg.parts = {{struct('functionResponse', functionResponse)}};
        contents{end+1} = geminiMsg; %#ok<AGROW>
    end
end

end

function parts = convertContentToParts(msg)
%convertContentToParts Convert message content to Gemini parts format

parts = {};

if isfield(msg, 'images') && ~isempty(msg.images)
    % Handle multimodal content with images
    parts{end+1} = struct('text', msg.content);

    images = msg.images;
    for i = 1:numel(images)
        img = images{i};
        if startsWith(img, ("https://" | "http://"))
            % URL-based image - Gemini supports file URIs
            parts{end+1} = struct('fileData', struct(...
                'mimeType', 'image/jpeg', ...
                'fileUri', img)); %#ok<AGROW>
        else
            % Local file - base64 encode
            [~, ~, ext] = fileparts(img);
            mimeType = "image/" + erase(ext, ".");
            fid = fopen(img);
            im = fread(fid, '*uint8');
            fclose(fid);
            b64 = matlab.net.base64encode(im);
            parts{end+1} = struct('inlineData', struct(...
                'mimeType', mimeType, ...
                'data', b64)); %#ok<AGROW>
        end
    end
else
    % Text only
    parts = {{struct('text', msg.content)}};
end

end

function tools = convertToolsToGeminiFormat(functions)
%convertToolsToGeminiFormat Convert OpenAI-style function definitions to Gemini format
%
%   Gemini format:
%   tools: [{
%     "function_declarations": [{
%       "name": "...",
%       "description": "...",
%       "parameters": {...}
%     }]
%   }]

functionDeclarations = {};

for i = 1:numel(functions)
    func = functions{i};

    % Extract the function definition from OpenAI format
    if isfield(func, 'function')
        funcDef = func.function;
    else
        funcDef = func;
    end

    geminiFunc = struct();
    geminiFunc.name = funcDef.name;

    if isfield(funcDef, 'description')
        geminiFunc.description = funcDef.description;
    end

    if isfield(funcDef, 'parameters')
        % Convert parameter types to uppercase for Gemini
        geminiFunc.parameters = convertParametersToGeminiFormat(funcDef.parameters);
    end

    functionDeclarations{end+1} = geminiFunc; %#ok<AGROW>
end

tools = {{struct('function_declarations', {functionDeclarations})}};

end

function params = convertParametersToGeminiFormat(parameters)
%convertParametersToGeminiFormat Convert OpenAI JSON Schema to Gemini format

params = struct();

if isfield(parameters, 'type')
    params.type = upper(string(parameters.type));
end

if isfield(parameters, 'description')
    params.description = parameters.description;
end

if isfield(parameters, 'properties')
    props = parameters.properties;
    propNames = fieldnames(props);
    newProps = struct();
    for i = 1:numel(propNames)
        propName = propNames{i};
        propDef = props.(propName);
        newProps.(propName) = convertParametersToGeminiFormat(propDef);
    end
    params.properties = newProps;
end

if isfield(parameters, 'required')
    params.required = parameters.required;
end

if isfield(parameters, 'enum')
    params.enum = parameters.enum;
end

if isfield(parameters, 'items')
    params.items = convertParametersToGeminiFormat(parameters.items);
end

end

function toolConfig = convertToolChoice(toolChoice)
%convertToolChoice Convert OpenAI tool_choice to Gemini toolConfig

toolConfig = [];

if isempty(toolChoice)
    return;
end

if ischar(toolChoice) || isstring(toolChoice)
    switch string(toolChoice)
        case "none"
            toolConfig = struct('functionCallingConfig', struct('mode', 'NONE'));
        case "auto"
            toolConfig = struct('functionCallingConfig', struct('mode', 'AUTO'));
        case "required"
            toolConfig = struct('functionCallingConfig', struct('mode', 'ANY'));
        otherwise
            % Specific function name
            toolConfig = struct('functionCallingConfig', struct(...
                'mode', 'ANY', ...
                'allowedFunctionNames', {{toolChoice}}));
    end
elseif isstruct(toolChoice)
    % Handle struct format {"type": "function", "function": {"name": "..."}}
    if isfield(toolChoice, 'function') && isfield(toolChoice.function, 'name')
        funcName = toolChoice.function.name;
        toolConfig = struct('functionCallingConfig', struct(...
            'mode', 'ANY', ...
            'allowedFunctionNames', {{funcName}}));
    end
end

end
