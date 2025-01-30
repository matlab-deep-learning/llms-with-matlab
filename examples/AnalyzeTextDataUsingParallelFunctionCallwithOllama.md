
# Analyze Text Data Using Parallel Function Calls with Ollama

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/AnalyzeTextDataUsingParallelFunctionCallwithOllama.mlx](mlx-scripts/AnalyzeTextDataUsingParallelFunctionCallwithOllama.mlx) 

This example shows how to detect multiple function calls in a single user prompt and use this to extract information from text data.


Function calls allow you to describe a function to Ollama™ in a structured way. When you pass a function to the model together with a prompt, the model detects how often the function needs to be called in the context of the prompt. If the function is called at least once, then the model creates a JSON object containing the function and argument to request.


This example contains four steps:

-  Create an unstructured text document containing fictional customer data. 
-  Create a prompt, asking Ollama to extract information about different types of customers. 
-  Create a function that extracts information about customers. 
-  Combine the prompt and the function. Use Ollama to detect how many function calls are included in the prompt and to generate a JSON object with the function outputs. 
# Extracting data from text

The customer record contains fictional information. 

```matlab
record = ["Customer John Doe, 35 years old. Email: johndoe@email.com";
    "Jane Smith, age 28. Email address: janesmith@email.com";
    "Customer named Alex Lee, 29, with email alexlee@email.com";
    "Evelyn Carter, 32, email: evelyncarter32@email.com";
    "Jackson Briggs is 45 years old. Contact email: jacksonb45@email.com";
    "Aria Patel, 27 years old. Email contact: apatel27@email.com";
    "Liam Tanaka, aged 28. Email: liam.tanaka@email.com";
    "Sofia Russo, 24 years old, email: sofia.russo124@email.com"];
```

Define the function that extracts data from the customers record using the [`openAIFunction`](http://../doc/functions/openAIFunction.md) function.

```matlab
f = openAIFunction("extractCustomerData", "Extracts data from customer records");
f = addParameter(f, "name", type="string", description="customer name", RequiredParameter=true);
f = addParameter(f, "age", type="number", description="customer age");
f = addParameter(f, "email", type="string", description="customer email", RequiredParameter=true);
```

Create a message with the customer record and an instruction.

```matlab
record = join(record);
messages = messageHistory;
messages = addUserMessage(messages,"Extract data from the record: " + record);
```

Create a chat object. Specify the model to be `"mistral-nemo"`, which supports parallel function calls.

```matlab
model = "mistral-nemo";
chat = ollamaChat(model,"You are an AI assistant designed to extract customer data.",Tools=f);
```

Generate a response and extract the data.

```matlab
[~, singleMessage, response] = generate(chat,messages);
if response.StatusCode == "OK"
    funcData = [singleMessage.tool_calls.function];
    extractedData = struct2table([funcData.arguments])
else
    response.Body.Data.error
end
```
| |age|email|name|
|:--:|:--:|:--:|:--:|
|1|35|'johndoe@email.com'|'John Doe'|
|2|28|'janesmith@email.com'|'Jane Smith'|
|3|29|'alexlee@email.com'|'Alex Lee'|
|4|32|'evelyncarter32@email.com'|'Evelyn Carter'|
|5|45|'jacksonb45@email.com'|'Jackson Briggs'|
|6|27|'apatel27@email.com'|'Aria Patel'|
|7|28|'liam.tanaka@email.com'|'Liam Tanaka'|
|8|24|'sofia.russo124@email.com'|'Sofia Russo'|

# Calling an external function

In this example, use a local function `searchCustomerData` defined at the end of this script. 


Create a message with the information you would like to get from the local function. 

```matlab
prompt = "Who are our customers under 30 and older than 27?";
messages = messageHistory;
messages = addUserMessage(messages,prompt);
```

Define the function that retrieves customer information using `openAIFunction`.

```matlab
f = openAIFunction("searchCustomerData", "Get the customers who match the specified and age");
f = addParameter(f,"minAge",type="integer",description="The minimum customer age",RequiredParameter=true);
f = addParameter(f,"maxAge",type="integer",description="The maximum customer age",RequiredParameter=true);
```

Create a chat object with a model supporting function calls. 

```matlab
model = "mistral-nemo";
chat = ollamaChat(model,"You are an AI assistant designed to search customer data.",Tools=f);
```

Generate a response

```matlab
[~, singleMessage, response] = generate(chat,messages);
```

Check if the response contains a request for tool calling. Use `jsonencode` to display nested struct compactly.

```matlab
if isfield(singleMessage,'tool_calls')
    tcalls = singleMessage.tool_calls;
    disp(jsonencode(tcalls,PrettyPrint=true))
else
    response.Body.Data.error
end
```

```matlabTextOutput
{
  "function": {
    "name": "searchCustomerData",
    "arguments": {
      "maxAge": 30,
      "minAge": 28
    }
  }
}
```

And add the tool call to the message history.

```matlab
messages = addResponseMessage(messages,singleMessage);
```

Call the `searchCustomerData` function and add the results to the messages.

```matlab
messages = processToolCalls(extractedData,messages, tcalls);
```

Step 3: Generate a response with the function result.

```matlab
[txt, singleMessage, response] = generate(chat,messages);
if response.StatusCode == "OK"
    txt
else
    response.Body.Data.error
end
```

```matlabTextOutput
txt = 
    " Our customers under 30 and older than 27 are:
     
     - **Jane Smith**: Age: 28, Email: janesmith@email.com
     - **Alex Lee**: Age: 29, Email: alexlee@email.com
     - **Liam Tanaka**: Age: 28, Email: liam.tanaka@email.com"

```
# Helper functions

Function that searches specific customers based on age range

```matlab
function json = searchCustomerData(data, minAge, maxAge)
    result = data(data.age >= minAge & data.age <= maxAge,:);
    result = table2struct(result);
    json = jsonencode(result);
end

```

Function that uses the tool calls to execute the function and add the results to the messages

```matlab
function msg = processToolCalls(data, msg, toolCalls)
    for ii = 1:numel(toolCalls)
        funcId = "";
        if isfield(toolCalls(ii),"id")
            funcId = string(toolCalls(ii).id);
        end
        funcName = string(toolCalls(ii).function.name);
        if funcName == "searchCustomerData"
            funcArgs = toolCalls(ii).function.arguments;
            keys = fieldnames(funcArgs);
            if all(ismember(["minAge","maxAge"],keys))
                try
                    funcResult = searchCustomerData(data,funcArgs.minAge,funcArgs.maxAge);
                catch ME
                    error(ME.message)
                    return
                end
                msg = addToolMessage(msg, funcId, funcName, funcResult);
            else
                error("Unknown arguments provided: " + join(keys))
                return
            end
        else
            error("Unknown function called: " + funcName)
            return
        end
    end
end
```

*Copyright 2024\-2025 The MathWorks, Inc.*

