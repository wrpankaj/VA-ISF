% Multi Directional Incremental Sheet Punching Toolpath Generation Code
% Import Toolpath Coordinates from Excel file
clc
clear all
[filename, pathname, filterindex] = uigetfile( ...
            {'*.xlsx'  },'Choose file to be processed', ...
              'MultiSelect', 'off');
            if filterindex==0,;end
filename=cellstr(filename);
A = xlsread(horzcat(pathname,char(filename)));
X = A(:,1);
Y = A(:,2);
Z = A(:,3);
    % Plot initial toolpath coordinates
    figure(1)
    scatter3(X,Y,Z,1)
    axis equal
% Input Parameters
lambda = input(" Wavelength of required sinusoidal toolpath = ");
Amplitude = input(" Amplitude of required sinusoidal toolpath = ");
N = input(" Number of points to insert for each wavelength = ");
punch_angle = input(" Punching angle of the tool in degrees = ");
feed = input(" Feedrate of the tool = ");
choice = menu('Select Direction of tool motion','Clockwise','Anti-clockwise');

% Point Generation by Linear Interpolation

    % Initialize Variables
    u = numel(X);
    d_initial = zeros(u-1,1);
    n_gen = zeros(u-1,1);
    
    % Calculating number of points to generate
    for i = 1:u-1
        d_initial(i) = distance(X(i+1),Y(i+1),Z(i+1),X(i),Y(i),Z(i));
        n_gen(i) = fix(N*d_initial(i)/lambda);
    end
    
    % Initialize Variables
    X_gen = NaN(max(n_gen)+1,u);
    X_gen(1,u) = X(u);
    Y_gen = NaN(max(n_gen)+1,u);
    Y_gen(1,u) = Y(u);
    Z_gen = NaN(max(n_gen)+1,u);
    Z_gen(1,u) = Z(u);
    
    % Generated points ( including intial points )
    for i = 1:u-1
        for j = 1:n_gen(i)+1
            X_gen(j,i) = point_gen(X(i),X(i+1),j-1,n_gen(i));
            Y_gen(j,i) = point_gen(Y(i),Y(i+1),j-1,n_gen(i));
            Z_gen(j,i) = point_gen(Z(i),Z(i+1),j-1,n_gen(i));
        end
    end
    
    % Convert generated 2-D matrices to 1-D and remove NaN elements
    X_gen = X_gen(:);
    Y_gen = Y_gen(:);
    Z_gen = Z_gen(:);
    
    X_gen = rmmissing(X_gen);
    Y_gen = rmmissing(Y_gen);
    Z_gen = rmmissing(Z_gen);
    
    % Plot coordinates generated by interpolation
    %figure(2)
    %scatter3(X_gen,Y_gen,Z_gen,1)
    axis equal

% Generating Sinusoidal Variation in Z-Direction

    % Initialize Variables
    v = numel(X_gen);
    d_gen = zeros(v-1,1);
    time = zeros(v,1);
    X_wave = X_gen;
    Y_wave = Y_gen;
    Z_wave = zeros(v,1);
    Z_wave(1) = Z_gen(1);
    total_d = 0;
    
    % Implementing Sinusoidal Variation
    for i = 1:v-1
        d_gen(i) = distance(X_gen(i+1),Y_gen(i+1),Z_gen(i+1),X_gen(i),Y_gen(i),Z_gen(i));
        total_d = total_d + d_gen(i);
        time(i+1) = total_d/feed;
        Z_wave(i+1) = Z_gen(i+1) + Amplitude*(1+sin(((2*pi*feed*time(i+1))/lambda)-(pi/2)));
    end
    
    % Plot Coordinates of Sinusoidal Toolpath Points
    %figure(3)
    %scatter3(X_wave,Y_wave,Z_wave,1)
    axis equal
    
% Rotate Generated Sinusoidal Toolpath Points

    % Initialize Variables
    if choice == 1
        phi = 90 - punch_angle;
    else
        phi = punch_angle - 90;
    end
    
    % Final Rotation of Wave
    for i = 1:fix(v/N)
        xa = X_gen(N*(i-1)+1);
        xb = X_gen(N*i+1);
        ya = Y_gen(N*(i-1)+1);
        yb = Y_gen(N*i+1);
        za = Z_gen(N*(i-1)+1);
        zb = Z_gen(N*i+1);
        for j = 1:N
            x = X_wave(N*(i-1)+j);
            y = Y_wave(N*(i-1)+j);
            z = Z_wave(N*(i-1)+j);
            [x_rot, y_rot, z_rot] = transform(x,y,z,xa,ya,za,xb,yb,zb,phi);
            X_final(N*(i-1)+j) = x_rot;
            Y_final(N*(i-1)+j) = y_rot;
            Z_final(N*(i-1)+j) = z_rot;
        end
    end
    
    % Plot Coordinates of Sinusoidal Toolpath Points
    figure(4)
    scatter3(X_final,Y_final,Z_final,1)
    axis equal
    
% Functions used in the script

    % Distance between two points
    function dist = distance(x1,y1,z1,x2,y2,z2)
        dist = sqrt(((x2-x1)^2)+((y2-y1)^2)+((z2-z1)^2));
    end
    
    % Point Generation by Linear Interpolation
    function pgen = point_gen(x1,x2,j,n)
        pgen = x1 + (((x2-x1)*j)/(n+1));
    end
    
    % Wave transformation Matrix
    function [xf, yf, zf] = transform(x,y,z,xa,ya,za,xb,yb,zb,phi)
        denom = sqrt(((xb-xa)^2)+((yb-ya)^2)+((zb-za)^2));
        a = (xb-xa)/denom;
        b = (yb-ya)/denom;
        c = (zb-za)/denom;
        s_gamma = b/sqrt(b^2+c^2);
        c_gamma = c/sqrt(b^2+c^2);
        s_beta = -a/sqrt(a^2+b^2+c^2);
        c_beta = sqrt(b^2+c^2)/sqrt(a^2+b^2+c^2);
        Ta = [ 1 0 0 -xa; 0 1 0 -ya; 0 0 1 -za; 0 0 0 1];
        Rx = [ 1 0 0 0; 0 c_gamma -s_gamma 0; 0 s_gamma c_gamma 0; 0 0 0 1];
        Ry = [ c_beta 0 s_beta 0; 0 1 0 0; -s_beta 0 c_beta 0 ; 0 0 0 1];
        Rz = [ cosd(phi) -sind(phi) 0 0; sind(phi) cosd(phi) 0 0; 0 0 1 0; 0 0 0 1];
        P = inv(Ta)*inv(Rx)*inv(Ry)*Rz*Ry*Rx*Ta*[x; y; z; 1];
        xf = P(1);
        yf = P(2);
        zf = P(3);
    end