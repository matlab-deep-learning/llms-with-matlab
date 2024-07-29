
# Process Generated Text in Real Time by Using Ollama™ in Streaming Mode

To run the code shown on this page, open the MLX file in MATLAB: [mlx-scripts/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.mlx](mlx-scripts/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.mlx) 

This example shows how to process generated text in real time by using Ollama in streaming mode.


By default, when you pass a prompt to Ollama using `ollamaChat`, it generates a response internally and then outputs it in full at the end. To print out and format generated text as the model is generating it, use the `StreamFun` name\-value argument of the `ollamaChat` class. The streaming function is a custom function handle that tells the model what to do with the output.


The example includes two parts:

-  First, define and use a custom streaming function to print out generated text directly as the model generates it. 
-  Then, create an HTML UI Component and define and use a custom streaming function to update the UI Component in real time as the model generates text. 

To run this example, you need a running Ollama server. As written, the example uses the Mistral model.

```matlab
loadenv(".env")
addpath('../..')
```
# Print Stream Directly to Screen

In this example, the streamed output is printed directly to the screen. 


Define the function to print the returned tokens. 

```matlab
function printToken(token)
    fprintf("%s",token);
end
```

Create the chat object with the defined function as a handle. 

```matlab
chat = ollamaChat("mistral",StreamFun=@printToken);
```

Generate response to a prompt in streaming mode. 

```matlab
prompt = "What is Model-Based Design?";
generate(chat, prompt, MaxNumTokens=500);
```

```matlabTextOutput
 Model-Based Design (MBD) is an approach to system design, engineering, and modeling that uses graphical models to represent the functionality and behavior of systems. It emphasizes the creation of abstract, high-level models before implementing specific hardware or software components.

The key features of Model-Based Design are:

1. Graphical Representation: Instead of writing code, engineers create models using visual diagrams such as flowcharts, block diagrams, or state machines. This makes the system design more intuitive and easier for both experts and non-experts to understand.

2. Simulation: By simulating a model, engineers can evaluate its performance and functionality without building any physical hardware or writing actual code. This allows for rapid prototyping and iterative improvements during the design phase.

3. Code Generation: Once the model is validated through simulation and testing, it can be automatically converted into code ready for deployment on a variety of hardware platforms. This reduces development time and increases productivity by minimizing manual coding tasks.

4. Model Reuse and Reusability: Models can be reused across different systems and applications, saving time and effort in the design process. Additionally, modular models can be combined to create larger, more complex systems.

5. System Integration: MBD helps streamline system integration by providing a clear interface between subsystems and components. This makes it easier to integrate third-party libraries or software tools into a project.

Model-Based Design is widely used in control systems design, embedded systems, and hardware-software co-design across various industries such as automotive, aerospace, and telecommunications. It facilitates faster development cycles, improved system performance, reduced debugging time, and increased reliability.
```
# Print Stream to HTML UI Component

In this example, the streamed output is printed to the HTML component. 


Create the HTML UI component.

```matlab
fig = uifigure;
h = uihtml(fig,Position=[10,10,fig.Position(3)-20,fig.Position(4)-20]);
```

Initialize the content of the HTML UI component.

```matlab
resetTable(h);
```

Create the chat object with the function handle, which requires the `uihtml` object created earlier. 

```matlab
chat = ollamaChat("mistral",StreamFun=@(x) addChat(h,"assistant",x));
```

Add the user prompt to the table in the HTML UI component. Use messageHistory to keep a running history of the exchange.

```matlab
history = messageHistory;
userPrompt = "Tell me 5 jokes.";
addChat(h,"user",userPrompt);
history = addUserMessage(history,userPrompt);
```

Generate response to a prompt in streaming mode. 

```matlab
[txt,message] = generate(chat,history);
history = addResponseMessage(history,message);
```

Simulating a dialog, add another user input and AI response.

```matlab
userPrompt = "Could you please explain the third one?";
addChat(h,"user",userPrompt);
history = addUserMessage(history,userPrompt);
generate(chat,history);
```
# Helper functions

`resetTable`:

1.  Adds the basic HTML structure and the JavaScript that process the data change in MATLAB.
2. The JavaScript gets a reference to the table and changed data and if the 3rd element in the data is "new", adds a new row.
3. It populates the new row with two cells and update the cells from the first two elements of the data.
4. The new row is then appended to the table.
5. Otherwise, the JavaScript gets reference to the last cell of the last row of the table, and update it with the 2nd element of the data.
```matlab
function resetTable(obj)
    %RESETTABLE initialize the HTML UI component in the input argument.  
    mustBeA(obj,'matlab.ui.control.HTML')
    obj.HTMLSource =  ['<html>',...
        '<style>td { vertical-align: top; } th { text-align: left; }</style>', ...
        '<body><table>', ...
        '<tr><th>Role</th><th>Content</th></tr></table><script>', ...
        'function setup(htmlComponent) {', ...
        'htmlComponent.addEventListener("DataChanged", function(event) {', ... 
        '  var table = document.querySelector("table");', ...
        '  var changedData = htmlComponent.Data;', ...
        '  var lastRow = table.rows[table.rows.length - 1];', ...
        '  var lastSpeaker = lastRow.cells[0].textContent;', ...
        '  if (lastSpeaker === changedData[0]) {', ...
        '    var lastCell = lastRow.cells[lastRow.cells.length - 1];', ...
        '    lastCell.innerHTML += changedData[1];', ...
        '  } else { ', ...
        '    var newRow = document.createElement("tr");', ...
        '    var cell1 = document.createElement("td");', ...                    
        '    var cell2 = document.createElement("td");', ...
        '    cell1.innerHTML = changedData[0];', ...
        '    cell2.innerHTML = changedData[1];', ... 
        '    newRow.appendChild(cell1);', ...
        '    newRow.appendChild(cell2);', ...
        '    table.appendChild(newRow);', ...
        '}});}</script></body></html>'];
    obj.Data = [];
    drawnow
end
```

`addRow` adds text to the table in the HTML UI component

```matlab
function addChat(obj,role,content)
    %ADDCHAT adds a new row or updates the last row of the table
    mustBeA(obj,'matlab.ui.control.HTML')
    content = replace(content,newline,"<br>");
    obj.Data = {role,content};
    drawnow
end
```

*Copyright 2024 The MathWorks, Inc.*

