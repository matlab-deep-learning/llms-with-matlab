function [text, message, response] = callAnthropicChatAPI(messages, functions, nvp)
%callAnthropicChatAPI Calls the Anthropic Messages API
%
%   MESSAGES and FUNCTIONS should be structs matching the format
%   required by the Anthropic Messages API.
%   Ref: https://docs.anthropic.com/en/api/messages
%
%   Example
%
%   % Create messages struct (no system message - that's separate in Anthropic)
%   messages = {struct("role", "user", ...
%       "content", "What is the capital of France?")};
%
%   % Define your API key
%   apiKey = "your-api-key-here"
%
%   % Send a request
%   [text, message] = llms.internal.callAnthropicChatAPI(messages, [], ...
%       APIKey=apiKey, ModelName="claude-sonnet-4-20250514", MaxNumTokens=1024)

%   Copyright 2025 The MathWorks, Inc.

arguments
    messages
    functions
    nvp.ToolChoice
    nvp.ModelName
    nvp.Temperature
    nvp.TopP
    nvp.StopSequences
    nvp.MaxNumTokens
    nvp.ResponseFormat
    nvp.APIKey
    nvp.TimeOut
    nvp.StreamFun
    nvp.SystemPrompt
    nvp.sendRequestFcn
end

END_POINT = "https://api.anthropic.com/v1/messages";

% Build parameters for Anthropic API
parameters = llms.internal.buildAnthropicParameters(messages, functions, nvp);

% Use Anthropic-specific request sender
if isfield(nvp, 'sendRequestFcn') && ~isempty(nvp.sendRequestFcn)
    % For testing - use injected function but note it may not handle Anthropic headers
    [response, streamedText] = nvp.sendRequestFcn(parameters, nvp.APIKey, END_POINT, nvp.TimeOut, nvp.StreamFun);
else
    [response, streamedText] = llms.internal.sendAnthropicRequest(parameters, nvp.APIKey, END_POINT, nvp.TimeOut, nvp.StreamFun);
end

% Process response
if response.StatusCode == "OK"
    if isempty(nvp.StreamFun)
        % Non-streaming response
        message = parseAnthropicResponse(response.Body.Data);
    else
        % Streaming response - construct message from streamed text
        message = struct("role", "assistant", "content", streamedText);
    end

    % Extract text from message
    if isfield(message, 'tool_calls') && ~isempty(message.tool_calls)
        text = "";
    else
        text = string(message.content);
    end
else
    text = "";
    message = struct();
end
end

function message = parseAnthropicResponse(data)
%parseAnthropicResponse Convert Anthropic API response to OpenAI-like format
%
%   Anthropic response format:
%   {
%     "id": "msg_...",
%     "type": "message",
%     "role": "assistant",
%     "content": [{"type": "text", "text": "..."}],
%     "stop_reason": "end_turn",
%     "usage": {...}
%   }
%
%   Convert to OpenAI-like format for compatibility:
%   {
%     "role": "assistant",
%     "content": "..."
%   }

message = struct();
message.role = "assistant";

% Extract content
if isfield(data, 'content') && ~isempty(data.content)
    content = data.content;

    % Handle array of content blocks
    textParts = {};
    toolCalls = {};

    if iscell(content)
        blocks = content;
    elseif isstruct(content)
        blocks = num2cell(content);
    else
        blocks = {content};
    end

    for i = 1:numel(blocks)
        block = blocks{i};
        if isstruct(block)
            if isfield(block, 'type')
                if strcmp(block.type, 'text') && isfield(block, 'text')
                    textParts{end+1} = block.text; %#ok<AGROW>
                elseif strcmp(block.type, 'tool_use')
                    % Convert to OpenAI-like tool call format
                    toolCall = struct();
                    toolCall.id = block.id;
                    toolCall.type = "function";
                    toolCall.function = struct();
                    toolCall.function.name = block.name;
                    if isfield(block, 'input')
                        if isstruct(block.input)
                            toolCall.function.arguments = jsonencode(block.input);
                        else
                            toolCall.function.arguments = string(block.input);
                        end
                    else
                        toolCall.function.arguments = "{}";
                    end
                    toolCalls{end+1} = toolCall; %#ok<AGROW>
                end
            end
        elseif ischar(block) || isstring(block)
            textParts{end+1} = block; %#ok<AGROW>
        end
    end

    % Set content
    if ~isempty(textParts)
        message.content = strjoin(textParts, "");
    else
        message.content = "";
    end

    % Set tool calls if any
    if ~isempty(toolCalls)
        message.tool_calls = [toolCalls{:}];
    end
else
    message.content = "";
end
end
