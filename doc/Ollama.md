# Ollama

This repository contains code to connect MATLAB to a local [Ollama®](https://ollama.com) server, running large language models (LLMs).

To use local models with Ollama, you will need to install and start an Ollama server, and “pull” models into it. Please follow the Ollama documentation for details. You should be familiar with the limitations and risks associated with using this technology, and you agree that you shall be solely responsible for full compliance with any terms that may apply to your use of any specific model.

Some of the [LLMs currently supported out of the box on Ollama](https://ollama.com/library) are:
- llama2, llama2-uncensored, llama3, codellama
- phi3
- aya
- mistral (v0.1, v0.2, v0.3)
- mixtral
- gemma, codegemma
- command-r

## Establishing a connection to local LLMs using Ollama

To create the chat assistant, call `ollamaChat` and specify the LLM you want to use:
```matlab
chat = ollamaChat("mistral");
```

`ollamaChat` has additional options, please run `help ollamaChat` for details.

## Simple call without preserving chat history

In some situations, you will want to use chat completion models without preserving chat history. For example, when you want to perform independent queries in a programmatic way.

Here's a simple example of how to use the `ollamaChat` for sentiment analysis, initialized with a few-shot prompt:

```matlab
% Initialize the Ollama Chat object, passing a system prompt

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

chat = ollamaChat("phi3",systemPrompt);

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
chat = ollamaChat("mistral");
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
chat = ollamaChat("mistral", StreamFun=sf);
txt = generate(chat,"What is Model-Based Design and how is it related to Digital Twin?");
% Should stream the response token by token
```

## Establishing a connection to remote LLMs using Ollama

To connect to a remote Ollama server, use the `Endpoint` parameter. Include the server name and port number (Ollama starts on 11434 by default):
```matlab
chat = ollamaChat("mistral",Endpoint="ollamaServer:11434");
```
