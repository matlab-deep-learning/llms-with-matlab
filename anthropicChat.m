classdef(Sealed) anthropicChat < llms.internal.textGenerator & ...
    llms.internal.hasTools & llms.internal.needsAPIKey
%anthropicChat Chat completion API from Anthropic.
%
%   CHAT = anthropicChat(systemPrompt) creates an anthropicChat object with the
%   specified system prompt.
%
%   CHAT = anthropicChat(systemPrompt,APIKey=key) uses the specified API key
%
%   CHAT = anthropicChat(systemPrompt,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   ModelName               - Name of the model to use for chat completions.
%                             The default value is "claude-sonnet-4-20250514".
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value is 1; higher values
%                             increase the randomness (in some sense,
%                             the "creativity") of outputs, lower values
%                             reduce it. Setting Temperature=0 removes
%                             randomness from the output altogether.
%
%   TopP                    - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1;
%                             lower values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as top-p sampling.
%
%   Tools                   - Array of openAIFunction objects representing
%                             custom functions to be used during chat completions.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%                             Example: ["The end.", "And that's all she wrote."]
%
%   TimeOut                 - Connection Timeout in seconds. Default value is 10.
%
%   StreamFun               - Function to callback when streaming the
%                             result
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json"
%
%   anthropicChat Functions:
%       anthropicChat        - Chat completion API from Anthropic.
%       generate             - Generate a response using the anthropicChat instance.
%
%   anthropicChat Properties:
%       ModelName            - Model name.
%
%       Temperature          - Temperature of generation.
%
%       TopP                 - Top probability mass to consider for generation.
%
%       StopSequences        - Sequences to stop the generation of tokens.
%
%       SystemPrompt         - System prompt.
%
%       FunctionNames        - Names of the functions that the model can
%                              request calls.
%
%       ResponseFormat       - The format of response the model returns.
%                              "text" | "json"
%
%       TimeOut              - Connection Timeout in seconds.

% Copyright 2025 The MathWorks, Inc.

    properties
        %MODELNAME   Model name.
        ModelName (1,1) string {mustBeModel} = "claude-sonnet-4-20250514"
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = []
    end

    methods
        function this = anthropicChat(systemPrompt, nvp)
            arguments
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.ModelName                (1,1) string {mustBeModel} = "claude-sonnet-4-20250514"
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopP                           {llms.utils.mustBeValidProbability} = 1
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat                 {mustBeAnthropicResponseFormat} = "text"
                nvp.APIKey                         {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.TimeOut                  (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 10
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
            end

            if isfield(nvp,"StreamFun")
                this.StreamFun = nvp.StreamFun;
            else
                this.StreamFun = [];
            end

            if isempty(nvp.Tools)
                this.Tools = [];
                this.FunctionsStruct = [];
                this.FunctionNames = [];
            else
                this.Tools = nvp.Tools;
                [this.FunctionsStruct, this.FunctionNames] = functionAsStruct(nvp.Tools);
            end

            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if systemPrompt ~= ""
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.ModelName = nvp.ModelName;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.StopSequences = nvp.StopSequences;
            this.ResponseFormat = nvp.ResponseFormat;
            this.APIKey = llms.internal.getApiKeyFromNvpOrEnv(nvp,"ANTHROPIC_API_KEY");
            this.TimeOut = nvp.TimeOut;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the anthropicChat instance.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(CHAT, MESSAGES) generates a response
            %   with the specified MESSAGES.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(__, Name=Value) specifies additional options
            %   using one or more name-value arguments:
            %
            %       MaxNumTokens     - Maximum number of tokens in the generated response.
            %                          Default value is 4096 (required for Anthropic API).
            %
            %       ToolChoice       - Function to execute. "none", "auto", "required",
            %                          or specify the function to call.
            %                          The default value is "auto".
            %
            %       Tools            - Array of openAIFunction objects representing
            %                          custom functions to be used during chat completions.
            %                          The default value is CHAT.Tools.
            %
            %       ModelName        - Name of the model to use for chat completions.
            %                          The default value is CHAT.ModelName.
            %
            %       Temperature      - Temperature value for controlling the randomness
            %                          of the output. Default value is CHAT.Temperature;
            %                          higher values increase the randomness (in some sense,
            %                          the "creativity") of outputs, lower values
            %                          reduce it. Setting Temperature=0 removes
            %                          randomness from the output altogether.
            %
            %       TopP             - Top probability mass value for controlling the
            %                          diversity of the output. Default value is CHAT.TopP;
            %                          lower values imply that only the more likely
            %                          words can appear in any particular place.
            %                          This is also known as top-p sampling.
            %
            %       StopSequences    - Vector of strings that when encountered, will
            %                          stop the generation of tokens. Default
            %                          value is CHAT.StopSequences.
            %                          Example: ["The end.", "And that's all she wrote."]
            %
            %       TimeOut          - Connection Timeout in seconds.
            %                          Default value is CHAT.TimeOut.
            %
            %       StreamFun        - Function to callback when streaming the
            %                          result. Default value is CHAT.StreamFun.
            %
            %       ResponseFormat   - The format of response the call returns.
            %                          Default value is CHAT.ResponseFormat.
            %                          "text" | "json"

            arguments
                this                    (1,1) anthropicChat
                messages                      {mustBeValidMsgs}
                nvp.ModelName           (1,1) string {mustBeModel} = this.ModelName
                nvp.Temperature               {llms.utils.mustBeValidTemperature} = this.Temperature
                nvp.TopP                      {llms.utils.mustBeValidProbability} = this.TopP
                nvp.StopSequences             {llms.utils.mustBeValidStop} = this.StopSequences
                nvp.ResponseFormat            {mustBeAnthropicResponseFormat} = this.ResponseFormat
                nvp.APIKey                    {llms.utils.mustBeNonzeroLengthTextScalar} = this.APIKey
                nvp.TimeOut             (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFun           (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
                nvp.MaxNumTokens        (1,1) {mustBeNumeric,mustBePositive} = 4096
                nvp.ToolChoice          (1,:) {mustBeTextScalar} = "auto"
                nvp.Tools               (1,:) {mustBeA(nvp.Tools, "openAIFunction")}
            end

            if ~isfield(nvp, 'Tools')
                functionsStruct = this.FunctionsStruct;
                functionNames = this.FunctionNames;
            else
                [functionsStruct, functionNames] = functionAsStruct(nvp.Tools);
            end

            mustBeValidFunctionCall(this, nvp.ToolChoice, functionNames);
            toolChoice = convertToolChoice(this, nvp.ToolChoice, functionNames);

            messages = convertCharsToStrings(messages);
            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = this.encodeImages(messages.Messages);
            end

            % Note: For Anthropic, system prompt is passed separately via SystemPrompt parameter
            % (not added to messages array like OpenAI)

            if isfield(nvp,"StreamFun")
                streamFun = nvp.StreamFun;
            else
                streamFun = this.StreamFun;
            end

            try % just for nicer errors, reducing the stack depth shown
                [text, message, response] = llms.internal.callAnthropicChatAPI(messagesStruct, functionsStruct,...
                    ModelName=nvp.ModelName, ToolChoice=toolChoice, Temperature=nvp.Temperature, ...
                    TopP=nvp.TopP, StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    ResponseFormat=nvp.ResponseFormat, SystemPrompt=this.SystemPrompt, ...
                    APIKey=nvp.APIKey, TimeOut=nvp.TimeOut, StreamFun=streamFun, ...
                    sendRequestFcn=this.sendRequestFcn);
            catch e
                throw(e);
            end

            if isfield(response.Body.Data,"error")
                err = response.Body.Data.error.message;
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err));
            end

            if ~isempty(text)
                text = llms.internal.reformatOutput(text,nvp.ResponseFormat);
            end
        end
    end

    methods(Hidden)
        function messageStruct = encodeImages(~, messageStruct)
            % Encode images for Anthropic API
            % Anthropic uses a slightly different format for images:
            % {"type": "image", "source": {"type": "base64", "media_type": "...", "data": "..."}}
            for k=1:numel(messageStruct)
                if isfield(messageStruct{k},"images")
                    images = messageStruct{k}.images;
                    messageStruct{k} = rmfield(messageStruct{k},"images");
                    if isfield(messageStruct{k},"image_detail")
                        messageStruct{k} = rmfield(messageStruct{k},"image_detail");
                    end
                    messageStruct{k}.content = ...
                        {struct("type","text","text",messageStruct{k}.content)};
                    for img = images(:).'
                        if startsWith(img,("https://"|"http://"))
                            % Anthropic supports URL images
                            s = struct( ...
                                "type", "image", ...
                                "source", struct("type", "url", "url", img));
                        else
                            % Base64 encode local image
                            [~,~,ext] = fileparts(img);
                            ext = lower(erase(ext,"."));
                            % Map extensions to MIME types
                            switch ext
                                case "jpg"
                                    mediaType = "image/jpeg";
                                case "jpeg"
                                    mediaType = "image/jpeg";
                                case "png"
                                    mediaType = "image/png";
                                case "gif"
                                    mediaType = "image/gif";
                                case "webp"
                                    mediaType = "image/webp";
                                otherwise
                                    mediaType = "image/" + ext;
                            end
                            % Read and encode image
                            fid = fopen(img);
                            im = fread(fid,'*uint8');
                            fclose(fid);
                            b64 = matlab.net.base64encode(im);
                            s = struct( ...
                                "type", "image", ...
                                "source", struct("type", "base64", ...
                                    "media_type", mediaType, ...
                                    "data", b64));
                        end
                        messageStruct{k}.content{end+1} = s;
                    end
                end
            end
        end
    end
end

function [functionsStruct, functionNames] = functionAsStruct(functions)
numFunctions = numel(functions);
functionsStruct = cell(1, numFunctions);
functionNames = strings(1, numFunctions);

for i = 1:numFunctions
    functionsStruct{i} = struct('type','function', ...
        'function',encodeStruct(functions(i)));
    functionNames(i) = functions(i).FunctionName;
end
end

function mustBeValidMsgs(value)
if isa(value, "messageHistory")
    if numel(value.Messages) == 0
        error("llms:mustHaveMessages", llms.utils.errorMessageCatalog.getMessage("llms:mustHaveMessages"));
    end
else
    try
        llms.utils.mustBeNonzeroLengthTextScalar(value);
    catch ME
        error("llms:mustBeMessagesOrTxt", llms.utils.errorMessageCatalog.getMessage("llms:mustBeMessagesOrTxt"));
    end
end
end

function mustBeModel(model)
    mustBeMember(model,llms.anthropic.models);
end

function mustBeAnthropicResponseFormat(format)
    % Anthropic doesn't support JSON Schema like OpenAI, only text or basic json hint
    if isstring(format) || ischar(format)
        mustBeMember(format, ["text", "json"]);
    else
        error("llms:invalidAnthropicResponseFormat", ...
            "ResponseFormat must be 'text' or 'json' for Anthropic API.");
    end
end
