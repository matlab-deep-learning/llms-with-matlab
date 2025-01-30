
# Process Generated Text in Real Time by Using Ollama™ in Streaming Mode

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.mlx](mlx-scripts/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.mlx) 

This example shows how to process generated text in real time by using Ollama in streaming mode.


By default, when you pass a prompt to Ollama using `ollamaChat`, it generates a response internally and then outputs it in full at the end. To print out and format generated text as the model is generating it, use the `StreamFun` name\-value argument of the `ollamaChat` class. The streaming function is a custom function handle that tells the model what to do with the output.


The example includes two parts:

-  First, define and use a custom streaming function to print out generated text directly as the model generates it. 
-  Then, create an HTML UI Component and define and use a custom streaming function to update the UI Component in real time as the model generates text. 

To run this example, you need a running Ollama server. As written, the example uses the Mistral® NeMo model.

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
chat = ollamaChat("mistral-nemo",StreamFun=@printToken);
```

Generate response to a prompt in streaming mode. 

```matlab
prompt = "What is Model-Based Design?";
generate(chat, prompt, MaxNumTokens=500);
```

```matlabTextOutput
Model-Based Design (MBD) is a software engineering approach that focuses on creating analyzable, understandable, and executable models of systems before physically implementing them. This method allows developers to simulate and validate designs at various levels of abstraction prior to final implementation in hardware or software. Here are some key aspects of Model-Based Design:

1. **Model Creation**: Models can be created using domain-specific languages like Simulink (for control, signal processing, image processing), Stateflow (for flowcharts and state machines), or MATLAB (for numerical computing). These tools provide a graphical interface for building models.

2. **Verification and Validation**: Models can be simulated and tested to verify their correctness and validate their behavior against requirements. Various verification techniques like code coverage analysis can also be applied on the models.

3. **Automatic Code Generation**: Once a model has been validated, it can be automatically converted into executable code targeting various hardware platforms (like embedded processors, FPGAs) or software environments (like C, C++, Java).

4. **Round-Trip Engineering**: In this approach, changes made to the generated code can propagate back to the original model, allowing for iterative development and refinement.

5. **Collaboration among Teams**: Model-Based Design enables collaboration among different engineering teams by providing a common design environment that captures the system's behavior accurately. This helps in reducing misinterpretations and speeds up development processes.

The benefits of Model-Based Design include improved productivity, earlier detection of errors, better requirement traceability, and enhanced communication among team members.

Industries where Model-Based Design is commonly used include automotive (control systems), aerospace (Avionics systems), consumer electronics (image processing algorithms), communications (signal processing), and more.
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
chat = ollamaChat("mistral-nemo",StreamFun=@(x) addChat(h,"assistant",x));
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
3. It populates the new row with two cells and updates the cells from the first two elements of the data.
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

