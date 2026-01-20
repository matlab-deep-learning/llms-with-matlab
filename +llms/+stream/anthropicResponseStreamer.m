classdef anthropicResponseStreamer < matlab.net.http.io.BinaryConsumer
%anthropicResponseStreamer Handles streaming responses from Anthropic API
%
%   Anthropic uses Server-Sent Events with event types:
%   - message_start: Contains message metadata
%   - content_block_start: Start of a content block
%   - content_block_delta: Incremental text content
%   - content_block_stop: End of a content block
%   - message_delta: Final message metadata (stop_reason, usage)
%   - message_stop: End of message
%
%   See: https://docs.anthropic.com/en/api/messages-streaming

%   Copyright 2025 The MathWorks, Inc.

    properties
        ResponseText = ""
        StreamFun
        Incomplete = ""
        ToolUseBlocks = {}
        CurrentToolId = ""
        CurrentToolName = ""
        CurrentToolInput = ""
    end

    methods
        function this = anthropicResponseStreamer(streamFun)
            this.StreamFun = streamFun;
        end
    end

    methods (Access=protected)
        function length = start(this)
            if this.Response.StatusCode ~= matlab.net.http.StatusCode.OK
                length = 0;
            else
                length = this.start@matlab.net.http.io.BinaryConsumer;
            end
        end
    end

    methods
        function [len, stop] = putData(this, data)
            [len, stop] = this.putData@matlab.net.http.io.BinaryConsumer(data);
            stop = doPutData(this, data, stop);
        end
    end

    methods (Access=private)
        function stop = doPutData(this, data, stop)
            % Extract the response text from Anthropic SSE format
            str = native2unicode(data', 'UTF-8');
            str = this.Incomplete + string(str);
            this.Incomplete = "";

            % Split into lines
            lines = split(str, newline);

            currentEvent = "";
            for i = 1:length(lines)
                line = strtrim(lines{i});

                if isempty(line)
                    continue;
                end

                % Parse SSE format
                if startsWith(line, "event: ")
                    currentEvent = extractAfter(line, "event: ");
                elseif startsWith(line, "data: ")
                    dataStr = extractAfter(line, "data: ");

                    % Handle incomplete JSON at end of chunk
                    try
                        json = jsondecode(dataStr);
                    catch
                        if i == length(lines)
                            this.Incomplete = lines{i};
                            return;
                        end
                        continue;
                    end

                    % Process based on event type
                    switch currentEvent
                        case "message_start"
                            % Message metadata - nothing to stream yet

                        case "content_block_start"
                            % Start of content block
                            if isfield(json, 'content_block')
                                block = json.content_block;
                                if isfield(block, 'type') && strcmp(block.type, 'tool_use')
                                    % Tool use block starting
                                    this.CurrentToolId = block.id;
                                    this.CurrentToolName = block.name;
                                    this.CurrentToolInput = "";
                                end
                            end

                        case "content_block_delta"
                            % Incremental content
                            if isfield(json, 'delta')
                                delta = json.delta;
                                if isfield(delta, 'type')
                                    if strcmp(delta.type, 'text_delta') && isfield(delta, 'text')
                                        txt = delta.text;
                                        this.StreamFun(txt);
                                        this.ResponseText = this.ResponseText + txt;
                                    elseif strcmp(delta.type, 'input_json_delta') && isfield(delta, 'partial_json')
                                        % Accumulate tool input JSON
                                        this.CurrentToolInput = this.CurrentToolInput + delta.partial_json;
                                    end
                                end
                            end

                        case "content_block_stop"
                            % End of content block
                            if ~isempty(this.CurrentToolId)
                                % Save completed tool use block
                                toolBlock = struct(...
                                    'id', this.CurrentToolId, ...
                                    'type', 'tool_use', ...
                                    'name', this.CurrentToolName, ...
                                    'input', this.CurrentToolInput);
                                this.ToolUseBlocks{end+1} = toolBlock;
                                this.CurrentToolId = "";
                                this.CurrentToolName = "";
                                this.CurrentToolInput = "";
                            end

                        case "message_delta"
                            % Message completion info (stop_reason, usage)
                            if isfield(json, 'delta') && isfield(json.delta, 'stop_reason')
                                if ismember(json.delta.stop_reason, ["end_turn", "stop_sequence", "tool_use"])
                                    stop = true;
                                end
                            end

                        case "message_stop"
                            % End of message
                            stop = true;

                        case "error"
                            % Error event
                            stop = true;
                    end
                end
            end
        end
    end
end
