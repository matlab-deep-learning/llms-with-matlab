%% Creating a Chatbot
% This script orchestrates a chat interaction with the OpenAI Chat Completions API, taking user
% inputs, maintaining a word count, and ensuring the chat remains within a 
% predefined word limit. 

% Set the maximum allowable number of words per chat session
wordLimit = 2000;

% Define the keyword that, when entered by the user, ends the chat session
stopWord = "end";


modelName = "gpt-3.5-turbo";
chat = openAIChat("You are a helpful assistant.", ModelName=modelName);

messages = openAIMessages;

query = "";
totalWords = 0;
messagesSizes = [];

% Main loop: continues indefinitely until the user inputs the stop word
while true
    % Prompt the user for input and convert it to a string
    query = input("User: ", "s");
    query = string(query);

    % If the user inputs the stop word, display a farewell message and exit the loop
    if query == stopWord
        disp("AI: Closing the chat. Have a great day!")
        break;
    end


    numWordsQuery = countNumWords(query);

    % If the query exceeds the word limit, display an error message and halt execution
    if numWordsQuery>wordLimit
        error("Your query should have less than 2000 words. You query had " + numWordsQuery + " words")
    end

    % Keep track of the size of each message and the total number of words used so far
    messagesSizes = [messagesSizes; numWordsQuery]; %#ok
    totalWords = totalWords + numWordsQuery;

    % If the total word count exceeds the limit, remove messages from the start of the session until it no longer does
    while totalWords > wordLimit
        totalWords = totalWords - messagesSizes(1);
        messages = removeMessage(messages, 1);
        messagesSizes(1) = [];
    end

    % Add the user's message to the session and generate a response using the OpenAI API
    messages = addUserMessage(messages, query);
    [text, response] = generate(chat, messages);

    disp("AI: " + text)

    % Count the number of words in the AI's response and update the total word count
    numWordsResponse = countNumWords(text);
    messagesSizes = [messagesSizes; numWordsResponse]; %#ok
    totalWords = totalWords + numWordsResponse;

    % Add the AI's response to the session
    messages = addResponseMessage(messages, response);
end

%% countNumWords function
% Function to count the number of words in a text string
function numWords = countNumWords(text)
    numWords = doclength(tokenizedDocument(text));
end