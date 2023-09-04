# Large Language Models with MATLAB®

This repository contains example code to demonstrate how to connect MATLAB to the OpenAI™ Chat Completions API (which powers ChatGPT™). This allows you to leverage the natural language processing capabilities of GPT models directly within your MATLAB environment.

The functionality shown here simply serves as an interface to the ChatGPT API. You should be familiar with the limitations and risks associated with using this technology as well as with [OpenAI terms and policies](https://openai.com/policies). You are responsible for any fees OpenAI may charge for the use of their API.

## Setup 
1. Clone the repository to your local machine.

    ```bash
    git clone https://github.com/matlab-deep-learning/llms-with-matlab.git
    ```
   
2. Open MATLAB and navigate to the directory where you cloned the repository.

3. Add the directory to the MATLAB path.

    ```matlab
    addpath('path/to/llms-with-matlab');
    ```

4. Set up your OpenAI API key. You can either:
    - Pass it directly to the `openAIChat` class, using the nvp `ApiKey`
    - Or set it as an environment variable.
    ```matlab
    setenv("OPENAI_API_KEY","your key here")
    ```

### MathWorks Products (https://www.mathworks.com)

Requires MATLAB release R2023a or newer
- Text Analytics Toolbox™


### 3rd Party Products:
3p:
- An active OpenAI API subscription and API key.


## Getting Started 

To get started, you can either create an `openAIChat` object and use its methods or use it in a more complex setup, as needed.

### Simple call without preserving chat history

In some situations, you will want to use GPT models without preserving chat history. For example, when you want to perform independent queries in a programmatic way. 

Here's a simple example of how to use the `openAIChat` for sentiment analysis:

```matlab
% Initialize the OpenAI Chat object, passing a system prompt

% The system prompt tells the assistant how to behave, in this case, as a sentiment analyzer
systemPrompt = "You are a sentiment analyser. You will look at a sentence and output"+...
    " a single word that classifies that sentence as either 'positive' or 'negative'."+....
    "Examples: \n"+...
    "The project was a complete failure. \n"+...
    "negative \n\n"+...  
    "The team successfully completed the project ahead of schedule."+...
    "positive \n\n"+...
    "His attitude was terribly discouraging to the team. \n"+...
    "negative \n\n";

chat = openAIChat(systemPrompt);

% Generate a response, passing a new sentence for classification
text = generate(chat, "The team is feeling very motivated")
% Should output "positive"
```

### Creating a chat system

If you want to create a chat system, you will have to create a history of the conversation and pass that to the `generate` function.

To start a conversation history, create a `openAIMessages` object:

```matlab
history = openAIMessages;
```

Then create the chat assistant:

```matlab
chat = openAIChat("You are a helpful AI assistant.");
```

Add a user message to the history and pass it to `generate`

```matlab
history = addUserMessage(history, "What is an eigenvalue?");
[text, response] = generate(chat, history)
```

The output `text` will contain the answer and `response` will contain the full response, which you need to include in the history as follows
```matlab
history = addResponseMessage(history, response);
```

You can keep interacting with the API and since we are saving the history, it will know about previous interactions.
```matlab
history = addUserMessage(history, "Generate MATLAB code that computes that");
[text, response] = generate(chat, history);
% Will generate code to compute the eigenvalue
```

### Passing functions to API

You can define functions that the API is allowed to request calls using `openAIFunction`. For example, to define the `editDistance` function for string values, you can do as follows:

```matlab
f = openAIFunction("editDistance", "Find edit distance between two strings or documents");
```

You also have to define what parameters the function can take, providing details on the properties of each parameter. The properties can be `type`, `description` or `enum`.

```matlab
f = addParameter(f, "str1", type="string", description="Source string.");
f = addParameter(f, "str2", type="string", description="Target string.");
```

Then you can pass the functions to the chat API as follows:

```matlab
chat = openAIChat("You are a helpful assistant", Functions=f);
```

The model will automatically determine if the function should be called based on the user input:

```matlab
history = openAIMessages;
history = addUserMessage(history, "What is the edit distance between MathWorks and MATLAB?");

[text, response] = generate(chat, history);
```

If the model sends back an empty `text` and a response containing a field `function_call`, it means it's requesting that you call a function. The model is not able to automatically execute a function. 

Once you have the result of the requested function, you can add the value to the history as a function message:

```
history = addFunctionMessage(history, "editDistance", "8"); 
```

Then the model can give a more precise answer based on the result of the function:
```
[text, response] = generate(chat, history);
```

## Examples
To learn how to use this in testing workflows, see [Examples](/examples/). 

- [ExampleBasicUsage.mlx](/examples/ExampleBasicUsage.mlx): A beginner's guide to using ChatGPT with a focus on parameter settings like temperature for controlling text generation.
- [ExampleSummarization.mlx](/examples/ExampleSummarization.mlx):  Learn to create concise summaries of long texts with ChatGPT.
- [ExampleChatBot.mlx](/examples/ExampleChatBot.mlx): Build a conversational chatbot capable of handling various dialogue scenarios using ChatGPT.
- [ExampleRetrievalAugmentedGeneration.mlx](/examples/ExampleRetrievalAugmentedGeneration.mlx): Enhance ChatGPT responses by integrating data retrieved from a separate knowledge base.
- [ExampleRobotControl.mlx](/examples/ExampleRobotControl.mlx): Translate natural language commands into robotic actions using ChatGPT.
- [ExampleAgentCreation.mlx](/examples/ExampleAgentCreation.mlx): Learn how to create agents capable of execting MATLAB functions.

## License

The license is available in the license.txt file in this GitHub repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023 The MathWorks, Inc.