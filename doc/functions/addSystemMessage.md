
# addSystemMessage

Add system message to message history


`updatedMessages = addSystemMessage(messages,name,content)`

# Description

You can use system messages to add example conversations to the message history.


Use example conversations in system messages for *few\-shot prompting*. Few\-shot prompting is a form of prompt engineering. Provide examples of user input and expected model output to a large language model to prompt its future behavior.


`updatedMessages = addSystemMessage(messages,name,content)` adds a system message to the `messageHistory` object `messages` and specifies the name of the speaker and the content of the message.

# Examples
## Generate Text from Example Conversation

First, specify the OpenAI® API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Connect to the OpenAI Chat Completion API. Use a system prompt to instruct the model.

```matlab
model = openAIChat("You are a helpful assistants who judges whether two English words rhyme. You answer either yes or no.");
```

Initialize the message history.

```matlab
messages = messageHistory;
```

Add example messages to the message history. When you pass this to the model, this example conversation further instructs the model on the output you want it to generate.

```matlab
messages = addSystemMessage(messages,"example_user","House and mouse?");
messages = addSystemMessage(messages,"example_assistant","Yes");
messages = addSystemMessage(messages,"example_user","Thought and brought?");
messages = addSystemMessage(messages,"example_assistant","Yes");
messages = addSystemMessage(messages,"example_user","Tough and though?");
messages = addSystemMessage(messages,"example_assistant","No");
```

Add a user message to the message history. When you pass this to the model, the system messages act as an extension of the system prompt. The user message acts as the prompt.

```matlab
messages = addUserMessage(messages,"Love and move?");
```

Generate a response from the message history.

```matlab
generate(model,messages)
```

```matlabTextOutput
ans = "No"
```
# Input Arguments
### `messages` — Message history

`messageHistory` object


Message history, specified as a [`messageHistory`](messageHistory.md) object.

### `name` — Name of the speaker

string scalar | character vector


Name of the speaker, specified as a string scalar or character vector. The name must be nonempty. 


To use system messages with an OpenAI API, the name must only contain letters, numbers, underscores (\_), and dashes (\-).


**Example**: `"example_assistant"`

### `content` — Message content

string scalar | character vector


Message content, specified as a string scalar or character vector. The content must be nonempty.

# Output Argument
### `updatedMessages` — Updated message history

`messageHistory` object


Updated message history, specified as a `messageHistory` object. The updated message history includes a new structure array with these fields:

-  role —`"system"` 
-  name — Set by the `name` input argument 
-  content — Set by the `content` input argument 
# See Also

[`generate`](generate.md) | [`messageHistory`](messageHistory.md) | [`openAIChat`](openAIChat.md) | [`ollamaChat`](ollamaChat.md) | [`azureChat`](azureChat.md) | [`addUserMessage`](addUserMessage.md) | [`addUserMessageWithImage`](http://addusermessagewithimage.md) | [`addToolMessage`](addToolMessage.md) | [`addResponseMessage`](addResponseMessage.md)


*Copyright 2024 The MathWorks, Inc.*

