%% Create Simple ChatBot
% This example shows how to create a simple chatbot using the |openAIChat| and 
% |openAIMessages| functions.
% 
% When you run this example, an interactive AI chat starts in the MATLAB Command 
% Window. To leave the chat, type "end" or press *Ctrl+C*.
%% 
% * This example includes three steps:
% * Define model parameters, such as the maximum word count, and a stop word.
% * Create an openAIChat object and set up a meta prompt.
% * Set up the chat loop.
%% 
% To run this example, you need a valid API key from a paid OpenAI API account.

loadenv(".env")
addpath('..') 
%% Setup Model
% Set the maximum allowable number of words per chat session and define the 
% keyword that, when entered by the user, ends the chat session. This example 
% uses the model |gpt-3.5-turbo|.

wordLimit = 2000;
stopWord = "end";
modelName = "gpt-3.5-turbo";
%% 
% Create an instance of |openAIChat| to perform the chat and |openAIMessages| 
% to store the conversation history|.|

chat = openAIChat("You are a helpful assistant. You reply in a very concise way, keeping answers limited to short sentences.", ModelName=modelName);
messages = openAIMessages;
%% Chat loop
% Start the chat and keep it going until it sees the word in |stopWord|.

totalWords = 0;
messagesSizes = [];
%% 
% The main loop continues indefinitely until you input the stop word or press 
% *Ctrl+C.*

while true
    query = input("User: ", "s");
    query = string(query);
    disp("User: " + query)
%% 
% If the you input the stop word, display a farewell message and exit the loop.

    if query == stopWord
        disp("AI: Closing the chat. Have a great day!")
        break;
    end

    numWordsQuery = countNumWords(query);
%% 
% If the query exceeds the word limit, display an error message and halt execution.

    if numWordsQuery>wordLimit
        error("Your query should have less than 2000 words. You query had " + numWordsQuery + " words")
    end
%% 
% Keep track of the size of each message and the total number of words used 
% so far.

    messagesSizes = [messagesSizes; numWordsQuery]; %#ok
    totalWords = totalWords + numWordsQuery;
%% 
% If the total word count exceeds the limit, remove messages from the start 
% of the session until it no longer does.

    while totalWords > wordLimit
        totalWords = totalWords - messagesSizes(1);
        messages = removeMessage(messages, 1);
        messagesSizes(1) = [];
    end
%% 
% Add the new message to the session and generate a new response.

    messages = addUserMessage(messages, query);
    [text, response] = generate(chat, messages);
    
    disp("AI: " + text)
%% 
% Count the number of words in the response and update the total word count.

    numWordsResponse = countNumWords(text);
    messagesSizes = [messagesSizes; numWordsResponse]; %#ok
    totalWords = totalWords + numWordsResponse;
%% 
% Add the response to the session.

    messages = addResponseMessage(messages, response);
end
%% |countNumWords| function
% Function to count the number of words in a text string

function numWords = countNumWords(text)
    numWords = doclength(tokenizedDocument(text));
end
%% 
% _Copyright 2023-2024 The MathWorks, Inc._