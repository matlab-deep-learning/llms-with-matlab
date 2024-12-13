classdef errorMessageCatalog
%errorMessageCatalog Stores the error messages from this repository

%   Copyright 2023-2024 The MathWorks, Inc.

    properties(Constant)
        %CATALOG dictionary mapping error ids to error msgs
        Catalog = buildErrorMessageCatalog;
    end

    methods(Static)
        function msg = getMessage(messageId, slot)
            %getMessage returns error message given a messageID and a SLOT.
            %   The value in SLOT should be ordered, where the n-th element
            %   will replace the value "{n}".

            arguments
                messageId {mustBeNonzeroLengthText}
            end
            arguments(Repeating)
                slot {mustBeNonzeroLengthText}
            end

            msg = llms.utils.errorMessageCatalog.Catalog(messageId);
            if ~isempty(slot)
                for i=1:numel(slot)
                    msg = replace(msg,"{"+i+"}", slot{i});
                end
            end
        end
    end
end

function catalog = buildErrorMessageCatalog
catalog = dictionary("string", "string");
catalog("llms:mustBeUnique") = "Values must be unique.";
catalog("llms:mustBeVarName") = "Parameter name must begin with a letter and contain not more than 'namelengthmax' characters.";
catalog("llms:parameterMustBeUnique") = "A parameter name equivalent to '{1}' already exists in Parameters. Redefining a parameter is not allowed.";
catalog("llms:mustBeAssistantCall") = "Input struct must contain field 'role' with value 'assistant', and field 'content'.";
catalog("llms:mustBeAssistantWithContent") = "Input struct must contain field 'content' containing text with one or more characters.";
catalog("llms:mustBeAssistantWithIdAndFunction") = "Field 'tool_call' must be a struct with fields 'id' and 'function'.";
catalog("llms:mustBeAssistantWithNameAndArguments") = "Field 'function' must be a struct with fields 'name' and 'arguments'.";
catalog("llms:assistantMustHaveTextNameAndArguments") = "Fields 'name' and 'arguments' must be text with one or more characters.";
catalog("llms:mustBeValidIndex") = "Index exceeds the number of array elements. Index must be less than or equal to {1}.";
catalog("llms:removeFromEmptyHistory") = "Unable to remove message from empty message history.";
catalog("llms:stopSequencesMustHaveMax4Elements") = "Number of stop sequences must be less than or equal to 4.";
catalog("llms:endpointMustBeSpecified") = "Unable to find endpoint. Either set environment variable AZURE_OPENAI_ENDPOINT or specify name-value argument ""Endpoint"".";
catalog("llms:deploymentMustBeSpecified") = "Unable to find deployment name. Either set environment variable AZURE_OPENAI_DEPLOYMENT or specify name-value argument ""DeploymentID"".";
catalog("llms:keyMustBeSpecified") = "Unable to find API key. Either set environment variable {1} or specify name-value argument ""APIKey"".";
catalog("llms:mustHaveMessages") = "Message history must not be empty.";
catalog("llms:mustSetFunctionsForCall") = "When no functions are defined, ToolChoice must not be specified.";
catalog("llms:mustBeMessagesOrTxt") = "Message must be nonempty string, character array, cell array of character vectors, or messageHistory object.";
catalog("llms:invalidOptionAndValueForModel") = "'{1}' with value '{2}' is not supported for model ""{3}"".";
catalog("llms:noStructuredOutputForModel") = "Structured output is not supported for model ""{1}"".";
catalog("llms:noStructuredOutputForAzureDeployment") = "Structured output is not supported for deployment ""{1}"".";
catalog("llms:structuredOutputRequiresAPI") = "Structured output is not supported for API version ""{1}"". Use APIVersion=""2024-08-01-preview"" or newer.";
catalog("llms:invalidOptionForModel") = "Invalid argument name {1} for model ""{2}"".";
catalog("llms:invalidContentTypeForModel") = "{1} is not supported for model ""{2}"".";
catalog("llms:functionNotAvailableForModel") = "Image editing is not supported for model ""{1}"".";
catalog("llms:promptLimitCharacter") = "Prompt must contain at most {1} characters for model ""{2}"".";
catalog("llms:pngExpected") = "Image must be a PNG file (*.png).";
catalog("llms:warningJsonInstruction") = "When using JSON mode, you must also prompt the model to produce JSON yourself via a system or user message.";
catalog("llms:apiReturnedError") = "Server returned error indicating: ""{1}""";
catalog("llms:apiReturnedIncompleteJSON") = "Generated output is not valid JSON: ""{1}""";
catalog("llms:dimensionsMustBeSmallerThan") = "Dimensions must be less than or equal to {1}.";
catalog("llms:stream:responseStreamer:InvalidInput") = "Input does not have the expected json format, got ""{1}"".";
catalog("llms:unsupportedDatatypeInPrototype") = "Invalid data type ''{1}'' in prototype. Prototype must be a struct, composed of numerical, string, logical, categorical, or struct.";
catalog("llms:incorrectResponseFormat") = "Invalid response format. Response format must be ""text"", ""json"", a struct, or a string with a JSON Schema definition.";
catalog("llms:OllamaStructuredOutputNeeds05") = "Structured output is not supported for Ollama version {1}. Use version 0.5.0 or newer.";
end
