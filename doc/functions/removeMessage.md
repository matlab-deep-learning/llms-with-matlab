
# removeMessage

Remove message from message history


`updatedMessages = removeMessage(messages,messageIndex)`

# Description

`updatedMessages = removeMessage(messages,messageIndex)` removes an existing message from the specified position in the [`messageHistory`](messageHistory.md) object `messages`.

# Examples
## Add Response Message to Message History

Initialize the message history.

```matlab
messages = messageHistory;
```

Add a user message to the message history.

```matlab
messages = addUserMessage(messages,"Why is a raven like a writing desk?");
```

Remove the message from the message history.

```matlab
messages = removeMessage(messages,1)
```

```matlabTextOutput
messages = 
  messageHistory with properties:

    Messages: {1x0 cell}

```
# Input Arguments
### `messages` — Message history

`messageHistory` object


Message history, specified as a [`messageHistory`](messageHistory.md) object.

### `messageIndex` — Message index

positive integer


Index of the message to remove, specified as a positive integer.

# Output Argument
### `updatedMessages` — Updated message history

`messageHistory` object


Updated message history, specified as a [`messageHistory`](messageHistory.md) object. 

# See Also

[`messageHistory`](messageHistory.md) | [`addSystemMessage`](addSystemMessage.md) | [`addUserMessage`](addUserMessage.md) | [`addToolMessage`](addToolMessage.md) | [`addResponseMessage`](addResponseMessage.md) | [`addUserMessageWithImages`](addUserMessageWithImages.md)

-  [Create Simple Chat Bot](../../examples/CreateSimpleChatBot.md) 
-  [Create Simple Ollama Chat Bot](../../examples/CreateSimpleOllamaChatBot.md) 

*Copyright 2024 The MathWorks, Inc.*

