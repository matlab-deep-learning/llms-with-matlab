
# addParameter

Add input argument to `openAIFunction` object

# Syntax

`fUpdated = addParameter(f,parameterName)`


`___ = addParameter(___,Name=Value)`

# Description

`fUpdated = addParameter(f,parameterName)` adds an input argument `parameterName` to the `openAIFunction` object `f`.


`___ = addParameter(___,Name=Value)` specifies additional options using one or more name\-value arguments.

# Examples
## Compute Sine Using OpenAI Function Call

First, specify the OpenAI® API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Create an `openAIFunction` object that represents the [`sind`](https://www.mathworks.com/help/matlab/ref/sind.html) function. The `sind` function has a single input argument, `x`, representing the input angle in degrees.

```matlab
f = openAIFunction("sind","Sine of argument in degrees");
f = addParameter(f,"x",type="number",description="Angle in degrees");
```

Connect to the OpenAI Chat Completion API. Pass the `openAIFunction` object `f` as an input argument.

```matlab
model = openAIChat("You are a helpful assistant.",Tools=f);
```

Initialize the message history. Add a user message to the message history.

```matlab
messages = messageHistory;
messages = addUserMessage(messages,"What is the sine of thirty?");
```

Generate a response based on the message history.

```matlab
[~,completeOutput] = generate(model,messages)
```

```matlabTextOutput
completeOutput = struct with fields:
          role: 'assistant'
       content: []
    tool_calls: [1x1 struct]
       refusal: []

```

The model has not generated any text. Instead, it has detected a function call, `completeOutput.tool_calls`.


Add the response to the message history.

```matlab
messages = addResponseMessage(messages,completeOutput);
```

Extract the tool call ID and the name of the called function.

```matlab
toolCallID = string(completeOutput.tool_calls.id)
```

```matlabTextOutput
toolCallID = "call_Scx4xE9whYiL2FbQWYslDgDr"
```

```matlab
functionCalled = string(completeOutput.tool_calls.function.name)
```

```matlabTextOutput
functionCalled = "sind"
```

Make sure that the model is calling the correct function. Even with only a single function, large language models can hallucinate function calls to fictitious functions.


Extract the input argument values from the complete output using the [`jsondecode`](https://www.mathworks.com/help/matlab/ref/jsondecode.html) function. Compute the sine of the generated argument value and add the result to the message history using the `addToolMessage` function.

```matlab
if functionCalled == "sind"
    args = jsondecode(completeOutput.tool_calls.function.arguments);
    result = sind(args.x)
    messages = addToolMessage(messages,toolCallID,functionCalled,"x="+result);
end
```

```matlabTextOutput
result = 0.5000
```

Finally, generate a natural language response.

```matlab
generatedText = generate(model,messages)
```

```matlabTextOutput
generatedText = "The sine of 30 degrees is 0.5."
```
# Input Arguments
### f — OpenAI function

[`openAIFunction`](openAIFunction.md) object


OpenAI function, specified as an `openAIFunction` object.

###  `parameterName` — Name of new input argument

string scalar | character array


Specify the name of the new input argument. The name must be a valid MATLAB variable name. 


For more information on variable naming rules in MATLAB, see [https://www.mathworks.com/help/matlab/matlab\_prog/variable\-names.html](https://www.mathworks.com/help/matlab/matlab_prog/variable-names.html).

## Name\-Value Arguments
### `RequiredParameter` — Flag to require argument

`true` (default) | `false`


Specify whether the argument is required (`true`) or optional (`false`).

### `description` — Argument description

string scalar | character vector


Natural language description of the input argument, specified as a string or character array.

### `type` — Argument type

string scalar | string vector | character vector


Data type or types of the input argument, specified as JSON data type. The possible argument types and their corresponding MATLAB data types are:

-   `"string"` — character vector 
-   `"number"` — scalar double 
-   `"integer"` — scalar integer 
-   `"object"` — scalar structure 
-   `"boolean"` — scalar logical 
-   `"null"` — `NaN` or empty double 

For more information on how to decode JSON\-formatted data in MATLAB, see [jsondecode](https://www.mathworks.com/help/matlab/ref/jsondecode.html).

### `enum` — List of possible argument values

string vector


List of all possible values of an input argument.


**Example**: `["on" "off" "auto"]`

# Output Argument
### `fUpdated` — Updated OpenAI function

`openAIFunction` object


Updated OpenAI function, specified as an `openAIFunction` object.

# See Also

[`openAIFunction`](openAIFunction.md) | [`openAIChat`](openAIChat.md) | [`generate`](generate.md) | [`addToolMessage`](addToolMessage.md)

-  [Analyze Scientific Papers Using ChatGPT Function Calls](../../examples/AnalyzeScientificPapersUsingFunctionCalls.md) 
-  [Analyze Text Data Using Parallel Function Calls with ChatGPT](../../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md) 

*Copyright 2024 The MathWorks, Inc.*

