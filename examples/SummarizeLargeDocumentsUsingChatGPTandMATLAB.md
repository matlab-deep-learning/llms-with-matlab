
# Summarize Large Documents Using ChatGPT™ and MATLAB®

To run the code shown on this page, open the MLX file in MATLAB: [mlx-scripts/SummarizeLargeDocumentsUsingChatGPTandMATLAB.mlx](mlx-scripts/SummarizeLargeDocumentsUsingChatGPTandMATLAB.mlx) 

This example shows how to use ChatGPT to summarize documents that are too large to be summarized at once.


To summarize short documents using ChatGPT, you can pass the documents directly as a prompt together with an instruction to summarize them. However, ChatGPT can only process prompts of limited size.


To summarize documents that are larger than this limit, split the documents up into smaller documents. Summarize the smaller document chunks, then pass all of the summaries to ChatGPT to generate one overall summary.

-  This example includes four steps: 
-  Download the complete text of "Alice in Wonderland" by Lewis Carroll from Project Gutenberg. 
-  Split the documents up into chunks of less than 3000 words.  
-  Use ChatGPT to create summaries of each chunk. 
-  Then use ChatGPT to create a summary of all of the summaries.  

To run this example, you need Text Analytics Toolbox™.


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
addpath('../..')
```
# Download Text Data

Download and read the content from Alice's Adventures in Wonderland by Lewis Carroll from Project Gutenberg.


First read the contents of the webpage.

```matlab
options = weboptions(Timeout=30);
code = webread("https://www.gutenberg.org/files/11/11-h/11-h.htm", options);
longText = extractHTMLText(string(code));
```
# Split Document Into Chunks

Large language models have a limit in terms of how much text they can accept as input, so if you try to summarize the complete book, you will likely get an error. A workaround is splitting the book into chunks and summarize each chunk individually. The chunk size is defined in `limitChunkWords`, which restricts the numbers of words in a chunk.

```matlab
incrementalSummary = longText;
limitChunkWords = 3000;
chunks = createChunks(incrementalSummary, limitChunkWords);
```
# Summarize Chunks

Initialize a ChatGPT session with the role of summarizing text

```matlab
summarizer = openAIChat("You are a professional summarizer.");
```

Looping process to gradually summarize the text chunk by chunk, reducing the chunk size with each iteration. 

```matlab
numCalls = 0;
while numel(chunks)>1
    summarizedChunks = strings(size(chunks));
    numCalls = numCalls + numel(chunks);
```

Add a limit to the number of calls, to ensure you are not making more calls than what is expected. You can change this value to match what is needed for your application.

```matlab
    if numCalls > 20
        error("Document is too long to be summarized.")
    end

    for i = 1:length(chunks)
     summarizedChunks(i) = generate(summarizer, "Summarize this content:" + newline + chunks(i));     
    end 
```

Merge the summarized chunks to serve as the base for the next iteration.

```matlab
    incrementalSummary = join(summarizedChunks);
```

Form new chunks with a reduced size for the subsequent iteration.

```matlab
    chunks = createChunks(incrementalSummary, limitChunkWords);
end
```
# Summarize Document

Compile the final summary by combining the summaries from all the chunks.

```matlab
fullSummary = generate(summarizer, "The following text is a combination of summaries. " + ...
    "Provide a cohese and coherent summary combining these smaller summaries, preserving as much information as possible:" + newline + incrementalSummary);
wrapText(fullSummary)
```

```matlabTextOutput
ans = 
    ""Alice's Adventures in Wonderland" by Lewis Carroll follows the whimsical journey of a young girl, Alice, who falls into a fantastical world through a rabbit hole.
     Throughout her adventures, Alice encounters a series of peculiar characters and bizarre events while trying to find her way back home.
     She navigates through surreal situations such as a Caucus-race with talking animals, converses with a cryptic Caterpillar about identity and size changes, and experiences a mad tea party with the March Hare and the Hatter.
     Alice also interacts with the Queen of Hearts during a chaotic croquet game, intervenes in a trial involving the theft of tarts, and meets the Mock Turtle and Gryphon who share odd stories and engage in whimsical discussions about lobsters and fish tails.
     The narrative is filled with illogical and imaginative elements, capturing readers' imaginations with its colorful and eccentric storytelling."

```
# `createChunks` function

This function segments a long text into smaller parts of a predefined size to facilitate easier summarization. It preserves the structure of sentences. The `chunkSize` should be large enough to fit at least one sentence.

```matlab
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
```
# `wrapText` function

This function splits text into sentences and then concatenates them again using `newline` to make it easier to visualize text in this example

```matlab
function wrappedText = wrapText(text)
wrappedText = splitSentences(text);
wrappedText = join(wrappedText,newline);
end
```

*Copyright 2023 The MathWorks, Inc.*

