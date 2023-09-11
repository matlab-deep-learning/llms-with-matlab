%% Summarization using ChatGPT
% This script leverages ChatGPT to summarize texts of different lengths.

%% Summarizing small documents
% In this part of the script, a ChatGPT session is initialized to summarize a short
% piece of text extracted from a webpage hosted by MathWorks.

% Initiating a ChatGPT session with the role defined as a professional summarizer
chat = openAIChat("You are a professional summarizer, create a summary of the provided text, be it an article, post, conversation, or passage.");


url = "https://www.mathworks.com/help/textanalytics";
code = webread(url);
shortText = extractHTMLText(string(code));

% Utilizing ChatGPT to create a summary of the extracted text
shortTextSummary = generate(chat, shortText)

%% Summarizing large documents
% This section of the script demonstrates how to incrementally summarize a large text
% by breaking it into smaller chunks and summarizing each chunk step by
% step. It uses as input text Romeo and Juliet, by William Shakespeare,
% from The Project Gutenberg.

options = weboptions(Timeout=30);
code = webread("https://www.gutenberg.org/files/1513/1513-h/1513-h.htm", options);
longText = extractHTMLText(string(code));

incrementalSummary = longText;

% Define the number of words in each chunk
limitChunkWords = 2000;

% Creating initial divisions of the text into chunks
chunks = createChunks(incrementalSummary, limitChunkWords);

% Initiating a ChatGPT session with the role of summarizing text
summarizer = openAIChat("You are a professional summarizer.");

% Looping process to gradually summarize the text chunk by chunk, reducing
% the chunk size with each iteration. 
while numel(chunks)>1
    summarizedChunks = strings(size(chunks));

    for i = 1:length(chunks)
     summarizedChunks(i) = generate(summarizer, "Summarize this content:" + newline + chunks(i));
    end
    
    % Merging the summarized chunks to serve as the base for the next iteration
    incrementalSummary = join(summarizedChunks);
    
    % Forming new chunks with a reduced size for the subsequent iteration
    chunks = createChunks(incrementalSummary, limitChunkWords);
end

% Compiling the final summary by combining the summaries from all the chunks
fullSummary = generate(summarizer, "Combine these summaries:" + newline + incrementalSummary)

%% CreateChunks function
% This function segments a long text into smaller parts of a predefined size 
% to facilitate easier summarization. It preserves the structure of
% sentences. The chunkSize should be large enough to fit at least one
% sentence.

function chunks = createChunks(text, chunkSize)
    % Tokenizing the input text for processing
    text = tokenizedDocument(text);
    
    % Splitting the tokenized text into individual sentences
    text = splitSentences(text);
    chunks = [];
    currentChunk = "";
    currentChunkSize = 0;
    
    % Iterating through the sentences to aggregate them into chunks until the chunk 
    % attains the predefined size, after which a new chunk is started
    for i=1:length(text)
        newChunkSize = currentChunkSize + doclength(text(i));
        if newChunkSize < chunkSize
            currentChunkSize = currentChunkSize + doclength(text(i));
            currentChunk = currentChunk + " " + joinWords(text(i));
        else
            chunks = [chunks; currentChunk]; %#ok
            currentChunkSize = doclength(text(i));
            currentChunk = joinWords(text(i));
        end
    end
end