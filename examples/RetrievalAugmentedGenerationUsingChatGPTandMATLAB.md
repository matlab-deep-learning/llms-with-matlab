
# Retrieval\-Augmented Generation Using ChatGPT and MATLAB

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.mlx](mlx-scripts/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.mlx) 

This example shows how to use retrieval\-augmented generation to generate answers to queries based on information contained in a document corpus. 


The example contains three steps:

-  Download and preprocess documents. 
-  Find documents relevant to a query using keyword search. 
-  Generate a response using ChatGPT™ based on the both the query and the most relevant source document. 

This example requires Text Analytics Toolbox™. 


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
```
# Download and Preprocess Documents

Specify the URLs of the reports.

```matlab
url = ["https://openknowledge.worldbank.org/bitstreams/0c18c872-91f0-51a4-ba91-c36b98893b4a/download"
    "https://openknowledge.worldbank.org/bitstreams/476f037b-a17e-484f-9cc2-282a2e5a929f/download"
    "https://openknowledge.worldbank.org/bitstreams/0c18c872-91f0-51a4-ba91-c36b98893b4a/download"];
```

Define the local path where the reports will be saved and download the reports using the provided URLs and save them to the specified local path.

```matlab
localpath = "./data/";
if ~exist(localpath, "dir")
    mkdir(localpath);
end
numFiles = numel(url);
for i = 1:numFiles
    filename = "WBD_" + i + ".pdf";
    local_file_name = fullfile(localpath, filename);
    if ~exist(local_file_name,"file")
        websave(local_file_name, url{i}, weboptions(Timeout=30));
    end
end
```

Define the function to read the text from the downloaded files.

```matlab
readFcn = @extractFileText;
file_pattern = [".txt",".pdf",".docx",".html",".htm"];
fds = fileDatastore(localpath,'FileExtensions',file_pattern,'ReadFcn',readFcn);

str = readall(fds);
str = [str{:}];
```

Split the text data into paragraphs with the helper function `preprocessDocuments`.

```matlab
documents = preprocessDocuments(str);
```

Initialize the chatbot with a system prompt and API key. Include your API key in the environment variable `OPENAI_API_KEY` or pass your key using the `APIKey` name\-value pair.

```matlab
chat = openAIChat("You are a helpful assistant. You will get a " + ...
    "context for each question, but only use the information " + ...
    "in the context if that makes sense to answer the question. " + ...
    "Let's think step-by-step, explaining how you reached the answer.");
```
# Retrieve Relevant Documents

Define the query, then retrieve and filter the relevant documents based on the query.

```matlab
query = "What technical criteria can be used to streamline new approvals for grid-friendly DPV?";
```

Tokenize the query and find similarity scores between the query and documents.

```matlab
embQuery = bm25Similarity(documents, tokenizedDocument(query));
```

Sort the documents in descending order of similarity scores.

```matlab
[~, idx] = sort(embQuery, "descend");
limitWords = 1000;
selectedDocs = [];
totalWords = 0;
```

Iterate over sorted document indices until word limit is reached

```matlab
i = 1;
while totalWords <= limitWords && i <= length(idx)
    totalWords = totalWords + doclength(documents(idx(i)));
    selectedDocs = [selectedDocs; joinWords(documents(idx(i)))];
    i = i + 1;
end
```
# Generate Response

Define the prompt for the chatbot and generate a response.

```matlab
prompt = "Context:" + join(selectedDocs, " ") + newline + ...
    "Answer the following question: " + query;
response = generate(chat, prompt);
```

Wrap the text for easier visualization.

```matlab
wrapText(response)
```

```matlabTextOutput
ans = 
    "The context provides information on how technical criteria can be used to 
     streamline new approvals for grid-friendly DPV. It mentions that technical 
     approvals for DPV installations to connect to the grid can be streamlined with 
     prudent screening criteria for systems that meet certain specifications. 
     Additionally, it emphasizes the importance of having a grid code that reflects 
     expected future growth of distributed energy resources.
     
     Therefore, the technical criteria that can be used to streamline new approvals 
     for grid-friendly DPV include having prudent screening criteria based on 
     specific specifications and ensuring that the grid code is in line with the 
     expected growth of distributed resources. This helps in facilitating the 
     connection of DPV installations to the grid efficiently and effectively."

```

# Helper Functions
```matlab
function allDocs = preprocessDocuments(str)
tokenized = tokenizedDocument(join(str,[newline newline]));
allDocs = splitParagraphs(tokenized);
end

function wrappedText = wrapText(text)
s = textwrap(text,80);
wrappedText = string(join(s,newline));
end
```
# References

*Energy Sector Management Assistance Program (ESMAP). 2023. From Sun to Roof to Grid: Power Systems and Distributed PV. Technical Report. Washington, DC: World Bank. License: Creative Commons Attribution CC BY 3.0 IGO*


*Copyright 2024 The MathWorks, Inc.*

