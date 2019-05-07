%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%              KEY FRAMES EXTRACTOR BASED ON AESTHETICS                  %
%                      AUTHOR SIMONE LIOTTA (2017)                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% COME USARE L'ESTRATTORE:

% 1)Inserisci il percorso del path da cui prelevare i frames da analizzare

% 2) Setta 'flag=1' se si vuole la classificazione tramite SVM e estrazione
% di features, 'flag=0', se si vuole la classificazione tramite Blur
% detection.

% 3)Inserisci un valore determinato sperimentalmente a seconda del caso in
% 'soglia' e 'delta_tresh', per avviare la motion detection.
% Se dà errore fai fare un primo iter con "delta_tresh=0", dopodichè dal
% secondo in poi tara i parametri a piacimento.
% Setta in 'perc' un valore compreso tra 0 e 100, che indica la
% percentuale di presenza dell'animale nella scena. 

% 4) Se si è scelta 

%    a) CLASSIFICAZIONE TRAMITE SVM,inserisci il percorso del path nella 
%       variabile percorso_TEST,seguita da'\detected_Frames' senza apici (LINE 74).

%    b) CLASSIFICAZIONE TRAMITE BLUR DETECTION,inserisci il percorso del path nella 
%       variabile percorso_TEST,seguita da'\detected_Frames' senza apici (LINE 206).

clear
clc
%% PARAMETRI DI INIZIALIZZAZIONE

% Locazione dei video frames da analizzare
percorso ='C:\Users\simo_\Desktop\TESI_PACK\Codici Matlab\n_6_Black_2';
flag=0;
soglia=10000;
delta_tresh=20;
perc=70;
%%
if flag==1
    
%Chiama la funzione di motion detection ed eseguila
%SL_motion_detector(soglia,delta_tresh,percorso )
[LTot,HTot] = maxBlobDim( soglia,delta_tresh,percorso );
percL=(perc*LTot)/100;
percH=(perc*HTot)/100;
SL_motion_detector(soglia,delta_tresh,percorso,percL,percH)

%Cambia directory di uscita e crea cartelle di output per i frames 
cd detected_Frames
cartella_LQ = './LQ_Frames/';
cartella_HQ = './HQ_Frames/';

if exist ('LQ_Frames') && exist ('HQ_Frames')
   rmdir LQ_Frames s
   rmdir HQ_Frames s
   mkdir LQ_Frames 
   mkdir HQ_Frames 
else
    mkdir LQ_Frames 
    mkdir HQ_Frames 
end

%Carico le features estratte dal training del classificatore

load Features_1.mat
LQ_counter=0;
HQ_counter=0;

%% INSERISCI PATH DI ACCESSO AI FRAMES SEGUITO DA "\detected_Frames" (CLASSIFICAZIONE SVM)

%Accedi a nuova directory di uscita e crea lista di frames detected da
%esaminare

percorso_TEST ='C:\Users\detected_Frames';
fileFolder_TEST = fullfile(percorso_TEST); 
dirOutput_TEST = dir(fullfile(fileFolder_TEST,'*.jpg'));
list_TEST = struct2cell((dirOutput_TEST));
test_list=cell(1,(length(dirOutput_TEST ))/2);
%%
if ~isempty(dirOutput_TEST)
    
for j=((length(dirOutput_TEST)/2)+1):(length(dirOutput_TEST))
    
    test_list{1,j-(length(dirOutput_TEST)/2)}=list_TEST{1,j};
    
end

percorso_CROP = percorso_TEST;
fileFolder_CROP = fullfile(percorso_CROP); 
dirOutput_CROP = dir(fullfile(fileFolder_CROP,'*.jpg'));
list_CROP = struct2cell(dirOutput_CROP);
test_crop=cell(1,(length(dirOutput_CROP))/2);


for j=1:(length(dirOutput_CROP))/2
    test_crop{1,j}=list_CROP{1,j};
    
end

setting.test_list = test_crop;
setting.proc_width = 240;
setting.proc_height = 180;
setting.hist_qL = 8;
setting.NCOLOR = 5;
setting.HSVcount_qL = 16;

%Scorri i frames nella lista
for s=1:length(test_list)
   
nome=test_crop{1,s};
image=imread(nome);
imshow(image)

nome_frame=test_list{1,s};
image_frame=imread(nome_frame);

%Estrai le Features estetiche
[testset] = Gen_test_set(image,setting, EdgeTemplate, LayoutTemplate, PaletteDictionary);


%crea vettore di label per la funzione svmpredict
test_labels = linspace(1,1,1);
[predictLabelL,accuracyLI,decision_valueL]= svmpredict(test_labels,testset,modelL,'-b 1');

%% SOLUZIONE DELLA FUNZIONE DI DECISIONE CON KERNEL LINEARE (NON USATA)

%accedi ai coefficienti nel modello
coeffSV=modelL.sv_coef;
%accedi ai support vectors determinati nel modello
SuppVect=modelL.SVs;
%trasponi i support vectors
SuppVect=SuppVect';
%moltiplica i due vettori
w=SuppVect*coeffSV ;
%estrai rho dal modello
rho=modelL.rho;

%% FASE DI TEST DEL CLASSIFICATORE SVM

%formula della funzione di decisione
decisionFunction=(((testset*w)-rho));
predizioneLabel=sign(decisionFunction);


%applicazione per visualizzare l'esito della classificazione
if predictLabelL==1 %predizioneLabel
    fprintf('Alta Qualità \n')
    HQ_counter=HQ_counter+1;
    baseFileName = sprintf('%d.jpg', s); 
    fullFileName = fullfile(cartella_HQ, baseFileName); 
    imwrite(image_frame, fullFileName);
else
    fprintf('Bassa Qualità \n')
    LQ_counter=LQ_counter+1;
    baseFileName = sprintf('%d.jpg', s); 
    fullFileName = fullfile(cartella_LQ, baseFileName); 
    imwrite(image_frame, fullFileName);
end

end

%conta quanti sono i frame in HQ e LQ
fprintf('Frames in HQ ')
fprintf('%d  \n', HQ_counter)
fprintf('Frames in LQ ')
fprintf('%d ', LQ_counter)
delete *.jpg

else
    clc 
    fprintf('NO KEY FRAMES DETECTED')
    
end

else 
%% CLASSIFICAZIONE TRAMITE BLUR DETECTION

%Chiama la funzione di motion detection ed eseguila
[LTot,HTot] = maxBlobDim(soglia,delta_tresh,percorso );
percL=(perc*LTot)/100;
percH=(perc*HTot)/100;
SL_motion_detector(soglia,delta_tresh,percorso,percL,percH)

%Cambia directory di uscita e crea cartelle di output per i frames 
cd detected_Frames
cartella_LQ = './LQ_Frames/';
cartella_HQ = './HQ_Frames/';

if exist ('LQ_Frames') && exist ('HQ_Frames')
   rmdir LQ_Frames s
   rmdir HQ_Frames s
   mkdir LQ_Frames 
   mkdir HQ_Frames 
else
    mkdir LQ_Frames 
    mkdir HQ_Frames 
end

LQ_counter=0;
HQ_counter=0;

%% INSERISCI PATH DI ACCESSO AI FRAMES SEGUITO DA "\detected_Frames" (BLUR DETECTION)

%accedi a nuova directory di uscita e crea lista di frames detected da
%esaminare
percorso_TEST ='C:\Users\simo_\Desktop\TESI_PACK\Codici Matlab\n_6_Black_2\detected_Frames';
fileFolder_TEST = fullfile(percorso_TEST); 
dirOutput_TEST = dir(fullfile(fileFolder_TEST,'*.jpg'));
list_TEST = struct2cell((dirOutput_TEST));
test_list=cell(1,(length(dirOutput_TEST ))/2);

if ~isempty(dirOutput_TEST)

for j=((length(dirOutput_TEST)/2)+1):(length(dirOutput_TEST))
   
    test_list{1,j-(length(dirOutput_TEST)/2)}=list_TEST{1,j};
    
end

percorso_CROP = percorso_TEST;
fileFolder_CROP = fullfile(percorso_CROP); 
dirOutput_CROP = dir(fullfile(fileFolder_CROP,'*.jpg'));
list_CROP = struct2cell(dirOutput_CROP);
test_crop=cell(1,(length(dirOutput_CROP))/2);


for j=1:(length(dirOutput_CROP))/2
    test_crop{1,j}=list_CROP{1,j};
    
end

setting.test_list = test_crop;
setting.proc_width = 240;
setting.proc_height = 180;
setting.hist_qL = 8;
setting.NCOLOR = 5;
setting.HSVcount_qL = 16;


%Scorri frames nella lista
for s=1:length(test_list)
   
nome=test_crop{1,s};
image=imread(nome);
imshow(image)

    [Image1,bool]=SobelBlur(image);
    
nome_frame=test_list{1,s};
image_frame=imread(nome_frame);

%applicazione per visualizzare l'esito della classificazione
if bool==1 
    fprintf('Alta Qualità \n')
    HQ_counter=HQ_counter+1;
    baseFileName = sprintf('%d.jpg', s); 
    fullFileName = fullfile(cartella_HQ, baseFileName); 
    imwrite(image_frame, fullFileName);
else
    fprintf('Bassa Qualità \n')
    LQ_counter=LQ_counter+1;
    baseFileName = sprintf('%d.jpg', s); 
    fullFileName = fullfile(cartella_LQ, baseFileName); 
    imwrite(image_frame, fullFileName);
end

end

%conta quanti sono i frame in HQ e LQ
fprintf('Frames in HQ ')
fprintf('%d  \n', HQ_counter)
fprintf('Frames in LQ ')
fprintf('%d ', LQ_counter)
delete *.jpg

else
    clc 
    fprintf('NO KEY FRAMES DETECTED')
    
end
end
    
    

