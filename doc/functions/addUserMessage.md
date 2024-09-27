
# addUserMessage

Add user message to message history


`updatedMessages = addUserMessage(messages,content)`

# Description

`updatedMessages = addUserMessage(messages,content)` adds a user message to the `messageHistory` object `messages` and specifies the content of the message.

# Examples
## Add User Message to Message History

Initialize the message history.

```matlab
messages = messageHistory;
```

Add a user message to the message history.

```matlab
messages = addUserMessage(messages,"Where is Natick located?");
messages.Messages{1}
```

```matlabTextOutput
ans = struct with fields:
       role: "user"
    content: "Where is Natick located?"

```
# Input Arguments
### `messages` — Message history

`messageHistory` object


Message history, specified as a [`messageHistory`](messageHistory.md) object.

### `content` — Message content

string scalar | character vector


Message content, specified as a string scalar or character vector. The content must be nonempty.

# Output Argument
### `updatedMessages` — Updated message history

`messageHistory` object


Updated message history, specified as a `messageHistory` object. The updated message history includes a new structure array with these fields:

-  role —`"user"` 
-  content — Set by the `content` input argument 
# See Also

[`messageHistory`](messageHistory.md) | [`generate`](generate.md) | [`openAIChat`](openAIChat.md) | [`ollamaChat`](ollamaChat.md) | [`azureChat`](azureChat.md) | [`addSystemMessage`](addSystemMessage.md) | [`addUserMessageWithImage`](addUserMessageWithImage.md) | [`addToolMessage`](addToolMessage.md) | [`addResponseMessage`](addResponseMessage.md)


*Copyright 2024 The MathWorks, Inc.*

