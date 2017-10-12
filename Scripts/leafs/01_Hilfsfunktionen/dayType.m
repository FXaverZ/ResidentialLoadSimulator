% dayType.m
% Autor: Christoph Lehner <e0925823@student.tuwien.ac.at>
% Erstellungsdatum: 2014-08-26
% Datum der letzten Revision:

function [ days ] = dayType

days = zeros(365,1);

%Winter 1.Januar bis 20.Maerz
%Uebergang 21.Maerz bis 14.Mai
%Sommer 15.Mai bis 14.September
%Uebergang 15.September bis 31.Oktober
%Winter 1.November bis 31.Dezember

%% Winter
% Erster Tag ist der Montag 1.Januar
% 31 + 29 + 20 = 80 Tage Winter
i = 0;

% Die ersten 11 Wochen
for j=1:11
    % 5 Werktage
    for k=1:5
        days(i+k) = 4;
    end
    i = i + k;
    % Samstag
    i = i + 1;
    days(i) = 2;
    % Sonntag
    i = i + 1;
    days(i) = 3;
end
i = i + 1;
% 11 Wochen * 7 Tage = 77 Tage

%Die restlichen Tage sind Werktage
for i=i:80
    days(i) = 4;
end
%% Uebergang
% 11 + 30 + 15 = 56 Tage
i = i + 1;
days(i) = 10; % 21.Maerz
i = i + 1;
days(i) = 10; % 22.Maerz

%Samstag 23.Maerz
i = i + 1;
days(i) = 8;

% Sonntag 24.Maerz
i = i + 1;
days(i) = 9;

% Die naechsten 7 Wochen
for j=1:7
    % 5 Werktage
    for k=1:5
        days(i+k) = 10;
    end
    i = i + k;
    % Samstag
    i = i + 1;
    days(i) = 8;
    % Sonntag
    i = i + 1;
    days(i) = 9;
end

for k=1:2
    days(i+k) = 10;
end
i = i + k;
%% Sommer
% 16 + 30 + 31 + 31 + 14 = 123 Tage
i = i + 1;
days(i) = 7; % 15.Mai
i = i + 1;
days(i) = 7; % 16.Mai
i = i + 1;
days(i) = 7; % 17.Mai

% Samstag
i = i + 1;
days(i) = 5;

% Sonntag
i = i + 1;
days(i) = 6;

% Die naechsten 16 Wochen
for j=1:16
    % 5 Werktage
    for k=1:5
        days(i+k) = 7;
    end
    i = i + k;
    % Samstag
    i = i + 1;
    days(i) = 5;
    % Sonntag
    i = i + 1;
    days(i) = 6;
end

for k=1:5
    days(i+k) = 7;
end
i = i + k;

i = i + 1;
days(i) = 5; % Samstag 14.September

%% Uebergang
% 16 + 31 = 47 Tage

i = i + 1;
days(i) = 9; % Sonntag 15.September

% Die naechsten 6 Wochen
for j=1:6
    % 5 Werktage
    for k=1:5
        days(i+k) = 10;
    end
    i = i + k;
    % Samstag
    i = i + 1;
    days(i) = 8;
    % Sonntag
    i = i + 1;
    days(i) = 9;
end

for k=1:4
    days(i+k) = 10;
end
i = i + k;

%% Winter
% 30 + 31 Tage
i = i + 1;
days(i) = 4;

i = i + 1;
days(i) = 2;

i = i + 1;
days(i) = 3;

% Die naechsten 8 Wochen
for j=1:8
    % 5 Werktage
    for k=1:5
        days(i+k) = 4;
    end
    i = i + k;
    % Samstag
    i = i + 1;
    days(i) = 2;
    % Sonntag
    i = i + 1;
    days(i) = 3;
end

for k=1:2
    days(i+k) = 4;
end
i = i + k;




end

