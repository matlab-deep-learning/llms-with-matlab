function stress = coilStress(wireDiameter, coilDiameter, maxLoad)

K = coilWahlsFactor(wireDiameter, coilDiameter);
stress = 8*K*maxLoad*coilDiameter/(pi*wireDiameter^3);

end