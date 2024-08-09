
# Retrieval\-Augmented Generation Using Ollama™ and MATLAB

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.mlx](mlx-scripts/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.mlx) 

This example shows how to use retrieval\-augmented generation to generate answers to queries based on information contained in a document corpus. 


The example contains three steps:

-  Download and preprocess documents. 
-  Find documents relevant to a query using keyword search. 
-  Generate a response using Ollama based on the both the query and the most relevant source document. 

This example requires Text Analytics Toolbox™ and a running Ollama service. As written, it requires the Mistral model to be installed in that Ollama instance.

```matlab
loadenv(".env")
addpath('../..')
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
    localFileName = fullfile(localpath, filename);
    if ~exist(localFileName,"file")
        websave(localFileName, url{i}, weboptions(Timeout=30));
    end
end
```

Define the function to read the text from the downloaded files.

```matlab
readFcn = @extractFileText;
filePattern = [".txt",".pdf",".docx",".html",".htm"];
fds = fileDatastore(localpath,'FileExtensions',filePattern,'ReadFcn',readFcn);

str = readall(fds);
str = [str{:}];
```

Split the text data into paragraphs with the helper function `preprocessDocuments`.

```matlab
documents = preprocessDocuments(str);
```

Initialize the chatbot with the model name (Mistral) and the a generic system prompt. Due to the long input created below, responses may take a long time on older machines; increase the accepted timeout.

```matlab
chat = ollamaChat("mistral", ...
    "You are a helpful assistant. You will get a " + ...
    "context for each question, but only use the information " + ...
    "in the context if that makes sense to answer the question. " + ...
    "Let's think step-by-step, explaining how you reached the answer.", ...
    TimeOut=600);
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
    " Technical criteria that can be used to streamline new approvals for 
     grid-friendly DPV include:
     
1. Adopting a grid code that reflects expected future growth of distributed
     energy resources, and updating it as necessary to balance deployment with the 
     technical requirements of distribution.
     2. Specifying advanced inverter functions today to reduce the need to change 
     systems in the future, making them easy to implement.
     3. Implementing prudent screening criteria for DPV installations that meet 
     certain specifications, which can streamline technical approvals. Such criteria 
     often rely on hosting capacity calculations to estimate the point where DPV 
     would induce technical impacts on system operations.
     4. Considering the value of ambitious investment options to accommodate 
     long-term developments and prioritizing the most cost-effective solutions in 
     assessing interventions for grid-friendly DPV. Costs can vary from one power 
     system to another, so case-by-case appraisal is important.
     5. Using metrics relevant to the impacts of DPV on low-voltage distribution 
     grids, such as DPV capacity penetration relative to minimum feeder daytime 
     load, to improve the use of technical screening criteria. Examples include 
     regulations that limit DPV installation size to a given percentage of the 
     customer's peak load, or countries with no limits on feeder penetration."

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

