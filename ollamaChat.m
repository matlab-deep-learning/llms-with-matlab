classdef (Sealed) ollamaChat < llms.internal.textGenerator
%ollamaChat Chat completion API from Ollama®.
%
%   CHAT = ollamaChat(modelName) creates an ollamaChat object for the given model.
%
%   CHAT = ollamaChat(__,systemPrompt) creates an ollamaChat object with the
%   specified system prompt.
%
%   CHAT = ollamaChat(__,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value depends on the model;
%                             if not specified in the model, defaults to 0.8.
%                             Higher values increase the randomness (in some
%                             sense, the “creativity”) of outputs, lower
%                             values reduce it. Setting Temperature=0 removes
%                             randomness from the output altogether.
%
%   TopP      - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1;
%                             lower values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as top-p sampling.
%
%   TopK       - Maximum number of most likely tokens that are
%                             considered for output. Default is Inf, allowing
%                             all tokens. Smaller values reduce diversity in
%                             the output.
%
%   TailFreeSamplingZ       - Reduce the use of less probable tokens, based on
%                             the second-order differences of ordered
%                             probabilities. Default value is 1, disabling
%                             tail-free sampling. Lower values reduce
%                             diversity, with some authors recommending
%                             values around 0.95. Tail-free sampling is
%                             slower than using TopP or
%                             TopK.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%                             Example: ["The end.", "And that's all she wrote."]
%
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json"
%
%   StreamFun               - Function to callback when streaming the
%                             result.
%
%   TimeOut                 - Connection Timeout in seconds. Default is 120.
%
%
%
%   ollamaChat Functions:
%       ollamaChat           - Chat completion API from OpenAI.
%       generate             - Generate a response using the ollamaChat instance.
%
%   ollamaChat Properties, in addition to the name-value pairs above:
%       Model                - Model name (as expected by Ollama server).
%
%       SystemPrompt         - System prompt.

% Ollama model properties not exposed:
%  repeat_last_n, repeat_penalty           - could not find an example where they made a difference
%  mirostat, mirostat_eta, mirostat_tau    - looking for the best API design


% Copyright 2024 The MathWorks, Inc.

    properties
        Model     (1,1) string
        TopK (1,1) {mustBeReal,mustBePositive} = Inf
        TailFreeSamplingZ (1,1) {mustBeReal} = 1
    end

    methods
        function this = ollamaChat(modelName, systemPrompt, nvp)
            arguments
                modelName                          {mustBeTextScalar}
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopP             {llms.utils.mustBeValidTopP} = 1
                nvp.TopK        (1,1) {mustBeReal,mustBePositive} = Inf
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat           (1,1) string {mustBeMember(nvp.ResponseFormat,["text","json"])} = "text"
                nvp.TimeOut                  (1,1) {mustBeReal,mustBePositive} = 120
                nvp.TailFreeSamplingZ        (1,1) {mustBeReal} = 1
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
            end

            if isfield(nvp,"StreamFun")
                this.StreamFun = nvp.StreamFun;
            else
                this.StreamFun = [];
            end

            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if ~(strlength(systemPrompt)==0)
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.Model = modelName;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.TopK = nvp.TopK;
            this.TailFreeSamplingZ = nvp.TailFreeSamplingZ;
            this.StopSequences = nvp.StopSequences;
            this.TimeOut = nvp.TimeOut;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the ollamaChat instance.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(CHAT, MESSAGES) generates a response
            %   with the specified MESSAGES.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(__, Name=Value) specifies additional options
            %   using one or more name-value arguments:
            %
            %       NumCompletions   - Number of completions to generate.
            %                          Default value is 1.
            %
            %       MaxNumTokens     - Maximum number of tokens in the generated response.
            %                          Default value is inf.
            %
            %       ToolChoice       - Function to execute. 'none', 'auto',
            %                          or specify the function to call.
            %
            %       Seed             - An integer value to use to obtain
            %                          reproducible responses

            arguments
                this                    (1,1) ollamaChat
                messages                (1,1) {mustBeValidMsgs}
                nvp.NumCompletions      (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBePositive} = inf
                nvp.Seed                {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = messages.Messages;
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end

            [text, message, response] = llms.internal.callOllamaChatAPI(...
                this.Model, messagesStruct, ...
                Temperature=this.Temperature, ...
                TopP=this.TopP, TopK=this.TopK,...
                TailFreeSamplingZ=this.TailFreeSamplingZ,...
                NumCompletions=nvp.NumCompletions,...
                StopSequences=this.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                ResponseFormat=this.ResponseFormat,Seed=nvp.Seed, ...
                TimeOut=this.TimeOut, StreamFun=this.StreamFun);

            if isfield(response.Body.Data,"error")
                err = response.Body.Data.error;
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err));
            end
        end
    end

    methods(Static)
        function mdls = models
            %ollamaChat.models - return models available on Ollama server
            %   MDLS = ollamaChat.models returns a string vector MDLS
            %   listing the models available on the local Ollama server.
            %
            %   These names can be used in the ollamaChat constructor.
            %   For names with a colon, such as "phi:latest", it is
            %   possible to only use the part before the colon, i.e.,
            %   "phi".
            endpoint = "http://localhost:11434/api/tags";
            response = webread(endpoint);
            mdls = string({response.models.name}).';
            baseMdls = unique(extractBefore(mdls,":latest"));
            % remove all those "mistral:latest", iff those are the only
            % model entries pointing at some model
            for base=baseMdls.'
                found = startsWith(mdls,base+":");
                if nnz(found) == 1
                    mdls(found) = [];
                end
            end
            mdls = unique([mdls(:); baseMdls]);
            mdls(strlength(mdls) < 1) = [];
            mdls(ismissing(mdls)) = [];
        end
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

function mustBeIntegerOrEmpty(value)
    if ~isempty(value)
        mustBeInteger(value)
    end
end
