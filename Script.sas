/**** Creation de la bibliotheque ****/

libname malib "/home/u63628432/Accident";

/* Importation des donnees*/

/* caracteristiques */

PROC IMPORT DATAFILE="/home/u63628432/Accident/caracteristiques-2018.csv"
            OUT= malib.caracteristiques2018
            DBMS=CSV
            REPLACE;
RUN;

/*  lieux */

PROC IMPORT DATAFILE="/home/u63628432/Accident/lieux-2018.csv"
            OUT=malib.lieux2018
            DBMS=CSV
            REPLACE;
RUN;

/* usagers */

PROC IMPORT DATAFILE="/home/u63628432/Accident/usagers-2018.csv"
            OUT=malib.usagers2018
            DBMS=CSV
            REPLACE;
RUN;

/* vehicules */

PROC IMPORT DATAFILE="/home/u63628432/Accident/vehicules-2018.csv"
            OUT= malib.vehicules2018
            DBMS=CSV
            REPLACE;
RUN;




/* ETUDES DESCRIPTIVES DES DONNEES */

/* caracteristique2018*/
proc means data= malib.caracteristiques2018;
run;

/*usagers*/
proc means data= malib.usagers2018;
run;

/* lieux */
proc means data = malib.lieux2018;
run;

/* vehicules */
proc means data= malib.vehicules2018;
run;

/* IDENTIFICATIONS DES VALEURS MANQUANTES */

/* caracteristiques */
proc means data= malib.caracteristiques2018 N NMISS;
run;

/* lieux */
proc means data= malib.lieux2018 N NMISS;
run;

/* vehicules */
proc means data=malib.vehicules2018 N NMISS;
run;

/* usagers */
proc means data= malib.usagers2018 NMISS ;
run ;


/* TRAITEMENT DES VALEURS MANQUANTES */

/* caracteristiques */

data malib.caracteristiques2018_cleaned;
    set malib.caracteristiques2018;
    if nmiss(atm, col, lat, long, dep) = 0;
run;

/* lieux */
data malib.lieux2018_cleaned;
    set malib.lieux2018;
    if nmiss(circ, nbv, pr, pr1, vosp, prof, plan, surf, infra, situ, env1) = 0;
run;

/* vechicule */
data malib.vehicules2018_cleaned;
    set malib.vehicules2018;
    if nmiss(senc, obs, obsm, choc, manv) = 0;
run;

/* usagers */
data malib.usagers2018_cleaned;
    set malib.usagers2018;
    if nmiss(place, trajet, secu, locp, actp, etatp, an_nais) = 0;
run;

/* SUPPRESSIONS DES DOUBLONS */

/*caracteristiques */
PROC SORT DATA= malib.caracteristiques2018_cleaned NODUPRECS;
    BY _all_;
RUN;

/* vehicules */
PROC SORT DATA= malib.vehicules2018_cleaned NODUPRECS;
    BY _all_;
RUN;

/* usagers */
PROC SORT DATA= malib.usagers2018_cleaned NODUPRECS;
    BY _all_;
RUN;

/* lieux */
PROC SORT DATA= malib.lieux2018_cleaned NODUPRECS;
    BY _all_;
RUN;




/* ANALYSE DES DONNEES */

/* 1. Quels sont les types de véhicules les plus susceptibles d'être impliqués 
dans des accidents graves en fonction des conditions météorologiques ? */
data malib.accidents1;
    merge malib.caracteristiques2018_cleaned(in=a) malib.vehicules2018_cleaned(in=b)
    malib.usagers2018_cleaned(in=c) ;
    by Num_Acc;
    if a and b and c;
run;
proc sql;
    create table malib.accidents_graves as
    select *
    from malib.accidents1
    where grav=2 and atm in (1, 2, 3, 4, 5, 6, 7, 8, 9); 
run;
/* Compter le nombre d'accidents par type de véhicule */
proc freq data= malib.accidents_graves;
    tables catv;
run;


/* 2. Quelle est le nombre d'accidents en fonction de la localisation 
(hors agglomération, en agglomération) et de la situation des lieux d'accidents */
data malib.accidents2;
    merge malib.caracteristiques2018_cleaned(in=a) malib.lieux2018_cleaned(in=b);
    by Num_Acc;
    if a and b;
run;

proc sql;
    select 
        case agg
            when 1 then 'Hors agglomération'
            else 'En agglomération'
        end as Localisation,
        case situ
            when 1 then 'Sur chaussée'
            when 2 then 'Sur bande d’arrêt d’urgence'
            when 3 then 'Sur accotement'
            when 4 then 'Sur trottoir'
            else 'Sur piste cyclable'
        end as Situation,
        count(*) as nb_accidents
    from malib.accidents2
    group by agg, situ
     order by nb_accidents desc;
run;

/* 3. Le nombre d'accidents impliquant des passagers en fonction de 
la localisation (hors agglomération, en agglomération) ? */

/* Fusion des données caractéristiques et usagers */
data malib.accidents3;
    merge malib.caracteristiques2018_cleaned(in=a) malib.usagers2018_cleaned(in=b) ;
    by Num_Acc;
    if a and b;
run;

/* Calcul du nombre d'accidents impliquant des passagers en fonction de la localisation */
proc sql;
    create table malib.accidents_passagers as
    select
        case
            when agg = 1 then 'Hors agglomération'
            else 'En agglomération'
        end as Localisation,
        count(*) as Nombre_Accidents_Passagers
    from malib.accidents3
    where catu = 2 /* 2 est le code pour les passagers */
    group by Localisation
    order by Nombre_Accidents_Passagers desc;
run;

/* Affichage des résultats */
proc print data=malib.accidents_passagers;
run;

/* Graphique de visualisation */
proc sgplot data=malib.accidents_passagers;
    vbar Localisation / response=Nombre_Accidents_Passagers 
        datalabel=Nombre_Accidents_Passagers;
    title "Nombre d'Accidents Impliquant des Passagers par Localisation";
run;



/* 4. Quelle est la répartition des types de véhicules impliqués dans les accidents
 en fonction de la localisation (hors agglomération, en agglomération) */

data malib.accidents4;
    merge malib.caracteristiques2018_cleaned(in=a) malib.vehicules2018_cleaned(in=b);
    by Num_Acc;
    if a and b;
run;

proc sql;
    create table malib.repartition_vehicules as
    select
        case 
            when agg = 1 then 'Hors agglomération'
            else 'En agglomération'
        end as Localisation,
        catv as Type_Vehicule,
        count(*) as Nombre_Accidents
    from malib.accidents4
    group by Localisation, Type_Vehicule;
run;


proc sgplot data=malib.repartition_vehicules;
    vbar Localisation / response=Nombre_Accidents group=Type_Vehicule;
    title "Répartition des Types de Véhicules Impliqués dans les Accidents par Localisation";
run;

/* 5. Comment les conditions météorologiques affectent-elles la fréquence et la gravité des accidents ? */

data malib.accidents5;
    merge malib.caracteristiques2018_cleaned (in=a) malib.usagers2018_cleaned (in=b);
    by Num_Acc;
    if a and b;
run;

proc freq data=malib.accidents5;
    tables atm;
run;

proc sql;
    create table malib.accidents_severity as
    select atm, grav, count(*) as Frequency
    from malib.accidents5
    group by atm, grav;
run;

proc sgplot data= malib.accidents_severity;
    vbar atm / response=Frequency group=grav;
    xaxis label='Conditions Météorologiques';
    yaxis label='Nombre d''Accidents'; 
run;





