
# Analyze Text Data Using Parallel Function Calls with ChatGPT™

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.mlx](mlx-scripts/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.mlx) 

This example shows how to detect multiple function calls in a single user prompt and use this to extract information from text data.


Function calls allow you to describe a function to ChatGPT in a structured way. When you pass a function to the model together with a prompt, the model detects how often the function needs to be called in the context of the prompt. If the function is called at least once, then the model creates a JSON object containing the function and argument to request.


This example contains four steps:

-  Create an unstructured text document containing fictional customer data. 
-  Create a prompt, asking ChatGPT to extract information about different types customers. 
-  Create a function that extracts information about customers. 
-  Combine the prompt and the function. Use ChatGPT to detect how many function calls are included in the prompt and to generate a JSON object with the function outputs. 

To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
addpath('../..')
```
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

Define the function that extract data from the customer record.

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

Create a chat object with a latest model. Only the new models support the parallel function calling.

```matlab
model = "gpt-3.5-turbo";
chat = openAIChat("You are an AI assistant designed to extract customer data.","ModelName",model,Tools=f);
```

Generate a response and extract the data.

```matlab
[~, singleMessage, response] = generate(chat,messages);
if response.StatusCode == "OK"
    funcData = [singleMessage.tool_calls.function];
    extractedData = arrayfun(@(x) jsondecode(x.arguments), funcData);
    extractedData = struct2table(extractedData)
else
    response.Body.Data.error
end
```
| |name|age|email|
|:--:|:--:|:--:|:--:|
|1|'John Doe'|35|'johndoe@email.com'|
|2|'Jane Smith'|28|'janesmith@email.com'|
|3|'Alex Lee'|29|'alexlee@email.com'|
|4|'Evelyn Carter'|32|'evelyncarter32@email.com'|
|5|'Jackson Briggs'|45|'jacksonb45@email.com'|
|6|'Aria Patel'|27|'apatel27@email.com'|
|7|'Liam Tanaka'|28|'liam.tanaka@email.com'|
|8|'Sofia Russo'|24|'sofia.russo124@email.com'|

# Calling an external function

In this example, use a local function `searchCustomerData` defined at the end of this script. 


Create a message with the information you would like to get from the local function. 

```matlab
prompt = "Who are our customers under 30 and older than 27?";
messages = messageHistory;
messages = addUserMessage(messages,prompt);
```

Define the function that retrieves weather information for a given city based on the local function.

```matlab
f = openAIFunction("searchCustomerData", "Get the customers who match the specified and age");
f = addParameter(f,"minAge",type="integer",description="The minimum customer age",RequiredParameter=true);
f = addParameter(f,"maxAge",type="integer",description="The maximum customer age",RequiredParameter=true);
```

Create a chat object with a latest model. 

```matlab
model = "gpt-3.5-turbo";
chat = openAIChat("You are an AI assistant designed to search customer data.",ModelName=model,Tools=f);
```

Generate a response

```matlab
[~, singleMessage, response] = generate(chat,messages);
```

Check if the response contains a request for tool calling.

```matlab
if isfield(singleMessage,'tool_calls')
    tcalls = singleMessage.tool_calls
else
    response.Body.Data.error
end
```

```matlabTextOutput
tcalls = struct with fields:
          id: 'call_JKENvUzMbNclCTI8GTBmY7YT'
        type: 'function'
    function: [1x1 struct]

```

And add the tool call to the messages.

```matlab
messages = addResponseMessage(messages,singleMessage);
```

Call `searchCustomerData` function and add the results to the messages

```matlab
messages = processToolCalls(extractedData,messages, tcalls);
```

Step 3: extend the conversation with the function result.

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
    "The customers who are under 30 and older than 27 are:
1. Jane Smith (age 28)
     2. Alex Lee (age 29)
     3. Liam Tanaka (age 28)"

```
# Helper functions

Function that searches specific customer based on age range

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
        funcId = string(toolCalls(ii).id);
        funcName = string(toolCalls(ii).function.name);
        if funcName == "searchCustomerData"
            funcArgs = jsondecode(toolCalls(ii).function.arguments);
            keys = fieldnames(funcArgs);
            vals = cell(size(keys));
            if ismember(keys,["minAge","maxAge"])
                for jj = 1:numel(keys)
                     vals{jj} = funcArgs.(keys{jj});
                end             
                try
                    funcResult = searchCustomerData(data,vals{:});
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

*Copyright 2024 The MathWorks, Inc.*

