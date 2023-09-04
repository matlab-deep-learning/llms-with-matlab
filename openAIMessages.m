classdef (Sealed) openAIMessages   
    %openAIMessages - Store and manage messages
    %   Creates an object to store and manage messages.
    %
    %   openAIMessages Properties:
    %       Messages - Cell array of messages in the conversation.
    %
    %   openAIMessages Methods:
    %       openAIMessages - Create an object to manage messages in a conversation.
    %       addSystemMessage - Add system message.
    %       addUserMessage - Add a user message.
    %       addFunctionMessage - Add a function message.
    %       addResponseMessage - Add a response message.
    %       removeMessage - Remove a message.
    %
    %   Example:
    %     % Create object with system prompt
    %     systemPrompt = "You are a helpful AI Assistant."
    %     messages = openAIMessages(systemPrompt);

    % Copyright 2023 The MathWorks, Inc.

    properties(SetAccess=private)
        % MESSAGES - Cell array of messages in the conversation.
        Messages = {}
    end
    
    methods
        function this = openAIMessages
            % openAIMessages Create an object to manage messages in a conversation.
            %   MESSAGES = openAIMessages creates an empty openAIMessages object.
            %
            %   Example:
            %     % Creates messages
            %     messages = openAIMessages;
        end

        function this = addSystemMessage(this, name, content)
            %addSystemMessage   Add system message.
            %   MESSAGES = addSystemMessage(MESSAGES, NAME, CONTENT) adds a system message with the
            %   specified NAME and CONTENT.
            %
            %   Input Arguments:
            %     MESSAGES    - openAIMessages instance.
            %                   openAIMessages object
            %
            %     NAME        - Name of the system message.
            %                   string scalar | character vector
            %
            %     CONTENT     - Content of the system message.
            %                   string scalar | character vector
            %
            %   Example:
            %     % Create object with system prompt
            %     systemPrompt = "You are a helpful AI Assistant. " + ...
            %         "You translate sentences from English to Portuguese";
            %     messages = openAIMessages(systemPrompt);
            %
            %    % Add system messages to provide examples of the conversation
            %    messages = addSystemMessage(messages, "example_user", "Hello, how are you?");
            %    messages = addSystemMessage(messages, "example_assistant", "Olá, como vai?");
            %    messages = addSystemMessage(messages, "example_user", "The sky is beautiful today");
            %    messages = addSystemMessage(messages, "example_assistant", "O céu está lindo hoje.");

            arguments
                this (1,1) openAIMessages 
                name (1,1) {mustBeNonzeroLengthText}
                content (1,1) {mustBeNonzeroLengthText}
            end

            newMessage = struct("role", "system", "name", name, "content", content);
            if isempty(this.Messages)
                this.Messages = {newMessage};
            else
                this.Messages{end+1} = newMessage;
            end
        end

        function this = addUserMessage(this, content)
            %addUserMessage   Add a user message.
            %   MESSAGES = addUserMessage( MESSAGES, CONTENT) adds a user message 
            %   with the specified CONTENT
            %
            %   Input Arguments:
            %      MESSAGES    - openAIMessages instance.
            %                    openAIMessages object
            %
            %     CONTENT      - Content of the user message.
            %                    string scalar | character vector
            %
            %   Example:
            %     % Create object with system prompt
            %     messages = openAIMessages("You are a helpful AI Assistant.");
            %
            %    % Add user message
            %    messages = addSystemMessage(messages, "Where is Natick located?");

            arguments
                this (1,1) openAIMessages
                content (1,1) {mustBeNonzeroLengthText}
            end

            newMessage = struct("role", "user", "content", content);
            if isempty(this.Messages)
                this.Messages = {newMessage};
            else
                this.Messages{end+1} = newMessage;
            end
        end

        function this = addFunctionMessage(this, name, content)
            % addFunctionMessage   Add a function message.
            %   MESSAGES = addFunctionMessage(MESSAGES, NAME, CONTENT) adds a function 
            %   message with the specified NAME and CONTENT.
            %
            %   Input Arguments:
            %     MESSAGES    - openAIMessages instance.
            %                   openAIMessages object
            %
            %     NAME        - Name of the function 
            %                   string scalar | character vector
            %
            %     CONTENT     - Content of the output obtained from the function
            %                   string scalar | character vector
            %
            %   Example:
            %
            %    % Create object with system prompt
            %    messages = openAIMessages("You are a helpful AI Assistant.");
            %
            %    % Add function message, containing the result of 
            %    % calling strcat("Hello", " World")
            %    messages = addFunctionMessage(messages, "strcat", "Hello World");

            arguments
                this (1,1) openAIMessages
                name (1,1) {mustBeNonzeroLengthText}
                content (1,1) {mustBeNonzeroLengthText}
            end

            newMessage = struct("role", "function", "name", name, "content", content);
            if isempty(this.Messages)
                this.Messages = {newMessage};
            else
                this.Messages{end+1} = newMessage;
            end
        end
       
        function this = addResponseMessage(this, messageStruct)
            % addResponseMessage   Add a response message.
            %   MESSAGES = addResponseMessage(MESSAGES, MESSAGESTRUCT) adds a response message with
            %   the specified message structure to the openAIMessages instance.
            %
            %   Input Arguments:
            %     THIS           - openAIMessages instance.
            %                      openAIMessages object
            %     MESSAGESTRUCT  - Structure representing the response message.
            %                      struct scalar
            %
            %   Example:
            %
            %   % Create object with system prompt
            %   messages = openAIMessages("You are a helpful AI Assistant.");
            %
            %   % Create an assistant message
            %   msg = struct("role", "assistant", "content", "How can I help?");
            %
            %   % Add message as a response
            %   addResponseMessage(messages, msg);

            arguments
                this (1,1) openAIMessages
                messageStruct (1,1) struct
            end

            if ~isfield(messageStruct, "role")||~isequal(messageStruct.role, "assistant")||~isfield(messageStruct, "content")
                error("llms:mustBeAssistantCall",llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantCall"));
            end

            % Assistant is asking for function call
            if isfield(messageStruct, "function_call")
                funCall = messageStruct.function_call;
                validateAssistantWithFunctionCall(funCall)
                this = addAssistantMessage(this,funCall.name, funCall.arguments);
            else
                % Simple assistant response
                validateRegularAssistant(messageStruct.content);
                this = addAssistantMessage(this,messageStruct.content);
            end
        end

        function this = removeMessage(this, idx)
            %removeMessage   Remove a message.
            %   THIS = removeMessage(THIS, IDX) removes a message at the specified index from
            %   the openAIMessages instance.
            %
            %   Input Arguments:
            %     THIS  - openAIMessages instance.
            %             openAIMessages object
            %     IDX   - Index of the message to be removed.
            %             positive integer scalar
            arguments
                this (1,1) openAIMessages
                idx (1,1) {mustBeInteger, mustBePositive}
            end
            if idx>numel(this.Messages)
                error("llms:mustBeValidIndex",llms.utils.errorMessageCatalog.getMessage("llms:mustBeValidIndex", string(numel(this.Messages))));
            end
            this.Messages(idx) = [];
        end
    end

    methods(Access=private)

        function this = addAssistantMessage(this, contentOrfunctionName, arguments)
            arguments
                this (1,1) openAIMessages
                contentOrfunctionName string
                arguments string = []
            end

            if isempty(arguments)
                % Default assistant call
                 newMessage = struct("role", "assistant", "content", contentOrfunctionName);
            else
                % function_call message
                functionCall = struct("name", contentOrfunctionName, "arguments", arguments);
                newMessage = struct("role", "assistant", "content", [], "function_call", functionCall);
            end
            
            if isempty(this.Messages)
                this.Messages = {newMessage};
            else
                this.Messages{end+1} = newMessage;
            end
        end
    end
end

function validateRegularAssistant(content)
try
    mustBeNonzeroLengthText(content)
    mustBeTextScalar(content)
catch ME
    error("llms:mustBeAssistantWithContent",llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantWithContent"))
end
end

function validateAssistantWithFunctionCall(functionCallStruct)
if ~isstruct(functionCallStruct)||~isfield(functionCallStruct, "name")||~isfield(functionCallStruct, "arguments")
    error("llms:mustBeAssistantWithNameAndArguments", ...
        llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantWithNameAndArguments"))
end

try
    mustBeNonzeroLengthText(functionCallStruct.name)
    mustBeTextScalar(functionCallStruct.name)
    mustBeNonzeroLengthText(functionCallStruct.arguments)
    mustBeTextScalar(functionCallStruct.arguments)
catch ME
    error("llms:assistantMustHaveTextNameAndArguments", ...
        llms.utils.errorMessageCatalog.getMessage("llms:assistantMustHaveTextNameAndArguments"))
end
end
