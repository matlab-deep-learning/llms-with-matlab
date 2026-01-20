classdef geminiResponseStreamer < matlab.net.http.io.BinaryConsumer
%geminiResponseStreamer Handles streaming responses from Google Gemini API
%
%   This class processes Server-Sent Events (SSE) from the Gemini
%   streamGenerateContent endpoint.
%
%   Gemini streaming format returns JSON objects with structure:
%   {
%     "candidates": [{
%       "content": {
%         "parts": [{"text": "..."}],
%         "role": "model"
%       },
%       "finishReason": "STOP"
%     }],
%     "usageMetadata": {...}
%   }

%   Copyright 2025 The MathWorks, Inc.

    properties
        ResponseText = ""
        StreamFun
        Incomplete = ""
        ToolCalls = {}
    end

    methods
        function this = geminiResponseStreamer(streamFun)
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

    methods (Access=?tgeminiResponseStreamer)
        function stop = doPutData(this, data, stop)
            % Extract response text from Gemini streaming format
            str = native2unicode(data', 'UTF-8');
            str = this.Incomplete + string(str);
            this.Incomplete = "";

            % Gemini streams JSON objects, potentially with 'data:' prefix
            str = split(str, newline);
            str = str(strlength(str) > 0);

            for i = 1:length(str)
                line = str{i};

                % Remove 'data: ' prefix if present (SSE format)
                if startsWith(line, "data: ")
                    line = extractAfter(line, "data: ");
                end

                % Skip empty lines or '[DONE]' marker
                if isempty(strtrim(line)) || strcmp(strtrim(line), '[DONE]')
                    continue;
                end

                % Skip array brackets that Gemini sometimes sends
                if strcmp(strtrim(line), '[') || strcmp(strtrim(line), ']') || strcmp(strtrim(line), ',')
                    continue;
                end

                try
                    json = jsondecode(line);
                catch ME
                    % If this is the last line, it might be incomplete
                    if i == length(str)
                        this.Incomplete = line;
                        return;
                    end
                    % Otherwise, skip malformed JSON
                    continue;
                end

                % Process the Gemini response structure
                if isfield(json, 'candidates') && ~isempty(json.candidates)
                    candidate = json.candidates(1);

                    % Check for finish reason
                    if isfield(candidate, 'finishReason')
                        finishReason = string(candidate.finishReason);
                        if ismember(finishReason, ["STOP", "MAX_TOKENS", "SAFETY"])
                            stop = true;
                        end
                    end

                    % Extract content from parts
                    if isfield(candidate, 'content') && isfield(candidate.content, 'parts')
                        parts = candidate.content.parts;

                        for j = 1:numel(parts)
                            part = parts(j);

                            if isfield(part, 'text')
                                % Text content
                                txt = part.text;
                                this.StreamFun(txt);
                                this.ResponseText = this.ResponseText + string(txt);

                            elseif isfield(part, 'functionCall')
                                % Function call
                                fc = part.functionCall;
                                toolCall = struct(...
                                    'id', "call_" + string(java.util.UUID.randomUUID()), ...
                                    'type', 'function', ...
                                    'function', struct(...
                                        'name', fc.name, ...
                                        'arguments', jsonencode(fc.args)));
                                this.ToolCalls{end+1} = toolCall;
                                % Signal function call to stream (empty string)
                                this.StreamFun('');
                            end
                        end
                    end
                end

                % Handle error responses
                if isfield(json, 'error')
                    stop = true;
                    return;
                end
            end
        end
    end
end
