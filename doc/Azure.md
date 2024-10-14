# Connecting to Azure OpenAI Service

This repository contains code to connect MATLAB to the [Azure® OpenAI® Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/).

To use Azure OpenAI Services, you need to create a model deployment on your Azure account and obtain one of the keys for it. You are responsible for any fees Azure may charge for the use of their APIs. You should be familiar with the limitations and risks associated with using this technology, and you agree that you shall be solely responsible for full compliance with any terms that may apply to your use of the Azure APIs.

Some of the [current LLMs supported on Azure](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models) are:
- GPT-4o (GPT-4 Omni)
- GPT-4 Turbo
- GPT-4
- GPT-3.5


## Setting up your Azure OpenAI Services API key

Set up your [endpoint and deployment and retrieve one of the API keys](https://learn.microsoft.com/en-us/azure/ai-services/openai/chatgpt-quickstart?tabs=command-line%2Cpython-new&pivots=rest-api#retrieve-key-and-endpoint). Create a `.env` file in the project root directory with the following content.

```
AZURE_OPENAI_ENDPOINT=<your endpoint>
AZURE_OPENAI_DEPLOYMENT=<your deployment>
AZURE_OPENAI_API_KEY=<your key>
```

You can use either `KEY1` or `KEY2` from the Azure configuration website.

Then load your `.env` file as follows:

```matlab
loadenv(".env")
```

## Establishing a connection to Chat Completions API using Azure

To connect MATLAB® to Chat Completions API via Azure, you will have to create an `azureChat` object. See [the Azure documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/chatgpt-quickstart) for details on the setup required and where to find your key, endpoint, and deployment name. As explained above, the endpoint, deployment, and key should be in the environment variables `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENYT`, and `AZURE_OPENAI_API_KEY`, or provided as `Endpoint=…`, `DeploymentID=…`, and `APIKey=…` in the `azureChat` call below.

In order to create the chat assistant, use the `azureChat` function, optionally providing a system prompt:
```matlab
chat = azureChat("You are a helpful AI assistant");
```

The `azureChat` object also allows to specify additional options. Call `help azureChat` for more information.
Compared to `openAIChat`, the `ModelName` option is not available due to the fact that the name of the LLM is already specified when creating the chat assistant.

## Simple call without preserving chat history

In some situations, you will want to use chat completion models without preserving chat history. For example, when you want to perform independent queries in a programmatic way.

Here's a simple example of how to use the `azureChat` for sentiment analysis, initialized with a few-shot prompt:

```matlab
% Initialize the Azure Chat object, passing a system prompt

% The system prompt tells the assistant how to behave, in this case, as a sentiment analyzer
systemPrompt = "You are a sentiment analyser. You will look at a sentence and output"+...
    " a single word that classifies that sentence as either 'positive' or 'negative'."+....
    newline + ...
    "Examples:" + newline +...
    "The project was a complete failure." + newline +...
    "negative" + newline + newline +...  
    "The team successfully completed the project ahead of schedule." + newline +...
    "positive" + newline + newline +...
    "His attitude was terribly discouraging to the team." + newline +...
    "negative" + newline + newline;

chat = azureChat(systemPrompt);

% Generate a response, passing a new sentence for classification
txt = generate(chat,"The team is feeling very motivated")
% Should output "positive"
```

## Creating a chat system

If you want to create a chat system, you will have to create a history of the conversation and pass that to the `generate` function.

To start a conversation history, create a `messageHistory` object:

```matlab
history = messageHistory;
```

Then create the chat assistant:

```matlab
chat = azureChat;
```

Add a user message to the history and pass it to `generate`:

```matlab
history = addUserMessage(history,"What is an eigenvalue?");
[txt, response] = generate(chat, history)
```

The output `txt` will contain the answer and `response` will contain the full response, which you need to include in the history as follows:
```matlab
history = addResponseMessage(history, response);
```

You can keep interacting with the API and since we are saving the history, it will know about previous interactions.
```matlab
history = addUserMessage(history,"Generate MATLAB code that computes that");
[txt, response] = generate(chat,history);
% Will generate code to compute the eigenvalue
```

## Streaming the response

Streaming allows you to start receiving the output from the API as it is generated token by token, rather than wait for the entire completion to be generated. You can specifying the streaming function when you create the chat assistant. In this example, the streaming function will print the response to the command window.
```matlab
% streaming function
sf = @(x) fprintf("%s",x);
chat = azureChat(StreamFun=sf);
txt = generate(chat,"What is Model-Based Design and how is it related to Digital Twin?")
% Should stream the response token by token
```

## Understanding the content of an image

You can use gpt-4o, gpt-4o-mini, or gpt-4-turbo to experiment with image understanding. 
```matlab
chat = azureChat("You are an AI assistant.",DeploymentID="gpt-4o");
image_path = "peppers.png";
messages = messageHistory;
messages = addUserMessageWithImages(messages,"What is in the image?",image_path);
[txt,response] = generate(chat,messages,MaxNumTokens=4096);
txt
% outputs a description of the image
```

## Calling MATLAB functions with the API

Optionally, `Tools=functions` can be used to provide function specifications to the API. The purpose of this is to enable models to generate function arguments which adhere to the provided specifications. 
Note that the API is not able to directly call any function, so you should call the function and pass the values to the API directly. This process can be automated as shown in [AnalyzeScientificPapersUsingFunctionCalls.mlx](/examples/AnalyzeScientificPapersUsingFunctionCalls.mlx), but it's important to consider that ChatGPT can hallucinate function names, so avoid executing any arbitrary generated functions and only allow the execution of functions that you have defined. 

For example, if you want to use the API for mathematical operations such as `sind`, instead of letting the model generate the result and risk running into hallucinations, you can give the model direct access to the function as follows:

```matlab
f = openAIFunction("sind","Sine of argument in degrees");
f = addParameter(f,"x",type="number",description="Angle in degrees.");
chat = azureChat("You are a helpful assistant.",Tools=f);
```

When the model identifies that it could use the defined functions to answer a query, it will return a `tool_calls` request, instead of directly generating the response:

```matlab
messages = messageHistory;
messages = addUserMessage(messages, "What is the sine of 30?");
[txt, response] = generate(chat, messages);
messages = addResponseMessage(messages, response);
```

The variable `response` should contain a request for a function call.
```bash
>> response

response = 

  struct with fields:

             role: 'assistant'
          content: []
       tool_calls: [1×1 struct]

>> response.tool_calls

ans = 

  struct with fields:

           id: 'call_wDpCLqtLhXiuRpKFw71gXzdy'
         type: 'function'
     function: [1×1 struct]

>> response.tool_calls.function

ans = 

  struct with fields:

         name: 'sind'
    arguments: '{↵  "x": 30↵}'
```

You can then call the function `sind` with the specified argument and return the value to the API add a function message to the history:

```matlab
% Arguments are returned as json, so you need to decode it first
id = string(response.tool_calls.id);
func = string(response.tool_calls.function.name);
if func == "sind"
    args = jsondecode(response.tool_calls.function.arguments);
    result = sind(args.x);
    messages = addToolMessage(messages,id,func,"x="+result);
    [txt, response] = generate(chat, messages);
else
    % handle calls to unknown functions
end
```

The model then will use the function result to generate a more precise response:

```shell
>> txt

txt = 

    "The sine of 30 degrees is approximately 0.5."
```

## Extracting structured information with the API

Another useful application for defining functions is to extract structured information from some text. You can just pass a function with the output format that you would like the model to output and the information you want to extract. For example, consider the following piece of text:

```matlab
patientReport = "Patient John Doe, a 45-year-old male, presented " + ...
    "with a two-week history of persistent cough and fatigue. " + ...
    "Chest X-ray revealed an abnormal shadow in the right lung." + ...
    " A CT scan confirmed a 3cm mass in the right upper lobe," + ...
    " suggestive of lung cancer. The patient has been referred " + ...
    "for biopsy to confirm the diagnosis.";
```

If you want to extract information from this text, you can define a function as follows:
```matlab
f = openAIFunction("extractPatientData","Extracts data about a patient from a record");
f = addParameter(f,"patientName",type="string",description="Name of the patient");
f = addParameter(f,"patientAge",type="number",description="Age of the patient");
f = addParameter(f,"patientSymptoms",type="string",description="Symptoms that the patient is having.");
```

Note that this function does not need to exist, since it will only be used to extract the Name, Age and Symptoms of the patient and it does not need to be called:

```matlab
chat = azureChat("You are helpful assistant that reads patient records and extracts information", ...
    Tools=f);
messages = messageHistory;
messages = addUserMessage(messages,"Extract the information from the report:" + newline + patientReport);
[txt, response] = generate(chat, messages);
```

The model should return the extracted information as a function call:
```shell
>> response

response = 

  struct with fields:

             role: 'assistant'
          content: []
        tool_call: [1×1 struct]

>> response.tool_calls

ans = 

  struct with fields:

           id: 'call_4VRtN7jb3pTPosMSb4ZaLoWP'
         type: 'function'
     function: [1×1 struct]

>> response.tool_calls.function

ans = 

  struct with fields:

         name: 'extractPatientData'
    arguments: '{↵  "patientName": "John Doe",↵  "patientAge": 45,↵  "patientSymptoms": "persistent cough, fatigue"↵}'
```

You can extract the arguments and write the data to a table, for example.
