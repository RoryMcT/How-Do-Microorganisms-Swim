function main()
% MAIN  
%       This version: June 2022
%
%   This code demonstrates the use of the method in simulating a
%   single swimming filament.
%
%   It uses the 'EJBb' version of Broyden's method (Algorithm 2 in the
%   paper) with a reduced 'robot arm' system of nonlinear equations.
%
%   To use, just run this script.


% Setup
save_to_file = true;
graphics = true;
video = true;
plot_step = 2;                % Plot every n timesteps
save_step = 150;                % Save data to file every n timesteps

% Filament data
a = 1;                        % segment 'radius' (half filament width)
N_sw = 3;                     % number of filaments
N_w = 15;                     % number of segments in filament
Np = N_sw*N_w;                % total number of segments
N_lam = N_sw*(N_w - 1);       % number of lambdas
max_broyden_steps = 3*Np;

steps_per_unit_time = 30;      % steps per oscillation
num_periods = 10;              % number of periods (unit) times
concheck_tol = 1e-4;          % Broyden's tolerance

DL = 2.2*a;                   % distance between segment centres, Delta L
L = N_w*DL;                   % filament length L
mu = 1;                       % fluid viscosity

omega = 0.1565; % Frequency of oscillation
Sp = 10.0; % Sperm number
T_0 = 11/L/1.2^4*2; %units of curvature
K_0 = 1; % Dimensionless wavenumber

% Derived parameters -----------------------------------------------
K = K_0.*2*pi/L;               %   1/L     dimensional wavenumber    
KB = 4*pi*omega*L^4*mu./Sp.^4; %  FL^2     bending modulus
KBdivDL = KB/DL;

period = 2*pi/omega;

filename = ['out-'  datestr(now,'yyyymmdd-HHMMSS') '-Nsw' num2str(N_sw) ...
            '-Nw' num2str(N_w) '-swim']; % used for data
                                         % file & video file

% Set up segment position vectors.
%   X_S is x^(j+1), i.e. at next timestep (which we are solving for)
%   X   is x^(j),   i.e. at current timestep
%   X_T is x^(j-1), i.e. at previous timestep

X = zeros(Np,1);         % x-coordinate at current timestep
Y = zeros(Np,1);         % y-coordinate
THETA = zeros(Np,1);     % rotation
TX = cos(THETA);         % tangent vector \hat{t}_x
TY = sin(THETA);         % tangent vector \hat{t}_y

X_T = zeros(Np,1);       % previous timestep
Y_T = zeros(Np,1);
THETA_T = zeros(Np,1);

X_S = zeros(Np,1);       % next timestep
Y_S = zeros(Np,1);
THETA_S = zeros(Np,1);

% Arrays storing which filament each segment belongs to
SW_IND = reshape([1:Np],N_w,N_sw)';

% Zero initial phase per worm
PHASE = zeros(N_sw,1);     

% Distances between segments and assign phases
DL_SW = zeros(N_sw, N_w - 1);
for i_sw = 1:N_sw
    PHASE(i_sw) = 0; %set to zero -> all the same initial phases
    DL_SW(i_sw,1) = DL;
    for j = 2:N_w-1
        DL_SW(i_sw,j) = DL;
    end
end

% Which filament does segment belong to?
% PtoS(n) returns the index of the filament that segment n belongs to.
PtoS = zeros(Np, 1);
PtoS = floor([0:Np-1]./N_w)+1;

% Set up position and orientation of first segment in every filament
% (We are happy with the default positon of [X,Y]=[0,0] and default
%  orientation of THETA=0 but you can change this here.)
vertical_spacing = 0.5*L;
for i_sw = 1:N_sw
    X(SW_IND(i_sw,1)) = (i_sw-1)*vertical_spacing;
end

% Having placed the first segment of each filament and set their
% orientation, use robot_arm to construct the position of the remaining
% segments. For more, type 'help robot_arm'.
[X,Y] = robot_arm(X,Y,THETA,SW_IND,DL);

% Zero the velocities and angular velocities of the segments
VX = zeros(Np,1);        % velocity of segment in x-direction
VY = zeros(Np,1);        % velocity of segment in y-direction
OMEGZ = zeros(Np,1);     % angular velocity of segment (in z-direction)

% Zero the forces and torques on the segments
FX = zeros(Np,1);        % force on each segment in x-direction
FY = zeros(Np,1);        % force on each segment in y-direction
TAUZ = zeros(Np,1);      % torque on each segment (in z-direction)

% Steric force setup.
% For explanation, type 'help collision_barrier'.
map = [1 1 1 1]';
list = [0:Np-1]';
head = Np;
Lx_collision = 1000;
Ly_collision = 1000;

% Initial guesses
X_T = X;
Y_T = Y;
THETA_T = THETA;
X_S = X;
Y_S = Y;
LAMBDA1 = zeros(N_lam,1);
LAMBDA2 = zeros(N_lam,1);
LAMBDA1_0 = zeros(N_lam,1);
LAMBDA2_0 = zeros(N_lam,1);

% Time
TOTAL_STEPS = num_periods*steps_per_unit_time;
dt = period/steps_per_unit_time;

t = 0;
plot_now = plot_step - 1;
save_now = save_step - 1;

% Segment size-related stuff
drag_coeff = (6*pi*a);
vis_tor_coeff = 8*pi*a^3;
RAD = a*ones(Np,1);         % Segment size vector (a = filament thickness)

% Newton step Delta X where at iteration k, X_(k+1) = X_k + Delta X
DeltaX = zeros(3*Np,1);

% Time and iteration counts
frame_time = zeros(TOTAL_STEPS,1);
iters = zeros(TOTAL_STEPS,1);       % Number of Broyden's iterations
running_total_count = 0;            % For average number of Broyden's iters

if video
    Filament_movie = VideoWriter(['output/' filename  '.avi']); % Name it.
    Filament_movie.FrameRate = 10;  % How many frames per second.
    open(Filament_movie);
    framecount = 1;
end

com_x = zeros(TOTAL_STEPS);

idx = reshape(reshape([1:3*Np],Np,3)',3*Np,1);   % For filament indexing

J0invERROR_VECk = zeros(3*Np,1);   % J_0^{-1} f(X_k)      in Algorithm 2
J0invERROR_VECk1 = zeros(3*Np,1);  % J_0^{-1} f(X_(k+1))  in Algorithm 2

for nt = 1:TOTAL_STEPS
    iter = 0;

    p_broy = max_broyden_steps + 1;
    Cmat = zeros(3*Np,p_broy); % c and d vectors from Alg 2, Line 7. Their
    Dmat = zeros(3*Np,p_broy); % value at each iteration is stored.

    % Stop if broken
    if isnan(X(1))
        keyboard
        continue
    end

    % Screen output
    fprintf('\n')
    if mod(nt,20) == 0
        fprintf(['[' filename ': rEJBb, RPY, Nsw=' ...
                 num2str(N_sw) ', Nw=' num2str(N_w) ']\n' ])
    end
    length_of_TOTAL_STEPS = max(ceil(log10(abs(TOTAL_STEPS))),1);
    fprintf([ '   ' ...
              'timestep: ' ...
              sprintf(['%' num2str(length_of_TOTAL_STEPS) '.f'],nt) ...
              '/' num2str(TOTAL_STEPS) ' ' ])
    frame_start = tic;

    % X_S is x^(j+1)
    % X   is x^(j)
    % X_T is x^(j-1)

    % Aim of this is to update X_S
    if(nt == 1)
        X_S = X;
        Y_S = Y;
        THETA_S = THETA;
        TX_S = cos(THETA_S);
        TY_S = sin(THETA_S);
    else
        % Rearranged linear interpolation as guess for x^(j+1), i.e.
        % x^j = 0.5*( x^(j-1) + x^(j+1) )
        THETA_S = 2.0*THETA - THETA_T;
        TX_S = cos(THETA_S);
        TY_S = sin(THETA_S);
        for j_sw = 1:N_sw
            first_bead_index = SW_IND(j_sw,1);
            X_S(first_bead_index) = 2*X(first_bead_index) - X_T(first_bead_index);
            Y_S(first_bead_index) = 2*Y(first_bead_index) - Y_T(first_bead_index);
        end
        % Having guessed first segment in filament, use robot_arm to guess rest
        [X_S,Y_S] = robot_arm(X_S,Y_S,THETA_S,SW_IND,DL);

    end

    % Find f(X_k) and place into ERROR_VECk.
    % If ||ERROR_VECk|| < concheck_tol (= epsilon in Alg 2, Line 4),
    % then concheck = 0. Else, 1.
    [concheck,ERROR_VECk,VY] = F(X_S,Y_S,TX_S,TY_S,THETA_S,LAMBDA1,LAMBDA2,concheck_tol);
    % (VY only being outputted here for calculating effective drag later.)

    % Find approximate Jacobian J_0
    J0 = approximate_jacobian_implicit_multiswim_reduced_clever(THETA, LAMBDA1, LAMBDA2, drag_coeff, vis_tor_coeff, dt, DL, KBdivDL, SW_IND);

    % Find J_0^{-1} f(X_k)  (from Alg 2, Line 5)
    J0invERROR_VECk(idx,:) = blockwise_backslash(J0,ERROR_VECk(idx,:),SW_IND);

    num_broydens_steps_required = 0;
    while(concheck == 1) % Alg 2, Line 4
        % Alg 2, Line 5. DeltaX is Delta X in paper.
        DeltaX = -H_mat_multiply(J0invERROR_VECk, Dmat, Cmat, ERROR_VECk, iter+1);

        % Update the positions and lambdas
        THETA_S = THETA_S + DeltaX(2*Np + 1:3*Np);
        TX_S = cos(THETA_S);
        TY_S = sin(THETA_S);
        for j_sw = 1:N_sw
            first_bead_index = SW_IND(j_sw,1);
            X_S(first_bead_index) = X_S(first_bead_index) + DeltaX(first_bead_index);
            Y_S(first_bead_index) = Y_S(first_bead_index) + DeltaX(Np + first_bead_index);
        end
        [X_S,Y_S] = robot_arm(X_S,Y_S,THETA_S,SW_IND,DL);
        lambda_locations = 1:2*Np;
        lambda_locations([1:N_w:end]) = [];
        DeltaX_lambdas = DeltaX(lambda_locations);
        LAMBDA1 = LAMBDA1 + DeltaX_lambdas(1:Np-N_sw);
        LAMBDA2 = LAMBDA2 + DeltaX_lambdas(Np-N_sw+1:2*Np-2*N_sw);

        % Check to see if the new state is an acceptable solution:
        % ERROR_VECk1 = f(X_(k+1))
        [concheck, ERROR_VECk1,VY] = F(X_S,Y_S,TX_S,TY_S,THETA_S,LAMBDA1,LAMBDA2,concheck_tol);

        iter = iter + 1;

        % (remaining lines are Alg 2, Line 7)
        y_vec = ERROR_VECk1 - ERROR_VECk;

        J0invERROR_VECk1(idx,:) = blockwise_backslash(J0,ERROR_VECk1(idx,:),SW_IND);

        Htimesf = H_mat_multiply(J0invERROR_VECk1, Dmat, Cmat, ERROR_VECk1, iter);
        y_vec_sq = y_vec'*y_vec;
        Dmat(:,iter) = Htimesf;
        Cmat(:,iter) = y_vec/y_vec_sq;
        ERROR_VECk = ERROR_VECk1;
        J0invERROR_VECk = J0invERROR_VECk1;

        % Shout if the iteration count has got a bit high
        if iter == 100
            keyboard
            continue
        end

        % If the number of iterations maxes out, proceed to next timestep
        % anyway and see what happens (but flag it with a *)
        if (iter > max_broyden_steps)
            fprintf(' *');
            concheck = 0;
        end

        num_broydens_steps_required = num_broydens_steps_required + 1;
        running_total_count = running_total_count + 1;
    end

    % Work out velocity of worm 1
    com_x(nt) = mean(X(1:N_w));
    if nt > steps_per_unit_time
        body_velocity_X = (com_x(nt) - com_x(nt-steps_per_unit_time))/(dt*steps_per_unit_time);        
    else
        body_velocity_X = 0;
    end

    % Step in time, step in time. Never need a reason, never need a rhyme..
    t = t + dt;
    X_T = X;
    Y_T = Y;
    THETA_T = THETA;
    X = X_S;
    Y = Y_S;
    THETA = THETA_S;
    TX = cos(THETA);
    TY = sin(THETA);

    % At later time steps, you can use a higher order approximation
    % for the initial guess of the Lagrange multipliers, while storing
    % the required past ones.
    if(nt > 10)
        if(nt == 11)
            LAMBDA1_0 = LAMBDA1;
            LAMBDA2_0 = LAMBDA2;
        elseif(nt == 12)
            LAMBDA1_T = 2.0*LAMBDA1 - LAMBDA1_0;
            LAMBDA2_T = 2.0*LAMBDA2 - LAMBDA2_0;

            LAMBDA1_m1 = LAMBDA1_0;
            LAMBDA2_m1 = LAMBDA2_0;

            LAMBDA1_0 = LAMBDA1;
            LAMBDA2_0 = LAMBDA2;

            LAMBDA1 = LAMBDA1_T;
            LAMBDA2 = LAMBDA2_T;
        else
            LAMBDA1_T = 3.0*LAMBDA1 - 3.0*LAMBDA1_0 + LAMBDA1_m1;
            LAMBDA2_T = 3.0*LAMBDA2 - 3.0*LAMBDA2_0 + LAMBDA2_m1;

            LAMBDA1_m1 = LAMBDA1_0;
            LAMBDA2_m1 = LAMBDA2_0;

            LAMBDA1_0 = LAMBDA1;
            LAMBDA2_0 = LAMBDA2;

            LAMBDA1 = LAMBDA1_T;
            LAMBDA2 = LAMBDA2_T;
        end
    end

    % Plot and save
    plot_now = plot_now + 1;
    save_now = save_now + 1;
    if(save_now == save_step && save_to_file)
        fid = fopen(['output/' filename '.dat'], 'a');
        if nt == 1
            fprintf(fid, 'dt, Nsw (RPY)\n');
            fprintf(fid, '%.6e %.6e %.f\n\n', dt, N_sw);
        end
        for j = 1:Np
            if mod(j,N_w) ~= 0 % i.e. if not the last segment in filament
                filament_id = floor(j/N_w); %0 to N_sw-1
                L1 = LAMBDA1(j-filament_id);
                L2 = LAMBDA2(j-filament_id);
            else
                L1 = 0; L2 = 0;
            end
            fprintf(fid, ['%.2f %.6f %.6f %.6f %.6f %.6f %.6f '...
                          '%.6f %.6f %.6f %.6f %.6f %.6f\n'], ...
                         t, X(j), Y(j), TX(j), TY(j), VX(j), VY(j), ...
                         OMEGZ(j), FX(j), FY(j), TAUZ(j), L1, L2);
        end
        fprintf(fid,'\n');
        fclose(fid);
        clf;
    end

    if(plot_now == plot_step && graphics)
        com_X = mean(X_S(1:N_w));
        com_X_all = mean(X_S);
        com_Y = mean(Y_S(1:N_w));
        for i_sw = 1:N_sw
            plot((X_S(SW_IND(i_sw,:)))/L, (Y_S(SW_IND(i_sw,:)))/L, ...
                '-','LineWidth',5);
            if i_sw == 1
                hold on
            end
        end

        % Work out quantifiable things about the first filament
        A_over_L = (max(Y_S(1:N_w)) - min(Y_S(1:N_w)))/L;
        title({['nt='  num2str(nt)  ', dt='  num2str(dt)  ...
            ', KB=' num2str(KB) ', Sp=' num2str(Sp) ...
            ', omega=' num2str(omega) ', T_0=' num2str(T_0) ...
            ', K_0=' num2str(K_0) ], ...
            ['Worm 1: COM/L=(' num2str(com_X/L) ',' num2str(com_Y/L) ...
            '), A/L=' num2str(A_over_L) ', VX/L\omega=' ...
            num2str(body_velocity_X/L/omega)]})


        hold off
        pbaspect([1 1 1])
        %xlim([com_X_all/L-0.5,com_X_all/L+0.5]);
        %ylim([com_Y/L-0.5,com_Y/L+0.5]);
        xlabel('(x-x_{COM})/L');
        ylabel('(y-y_{COM})/L');
        axis equal

        if video == true
            frame = getframe(gcf);
            writeVideo(Filament_movie,frame);
            framecount=framecount+1;
        end
        pause(0.01);
    end

    if plot_now == plot_step
        plot_now = 0;
    end
    if save_now == save_step
        save_now = 0;
    end

    frame_time(nt) = toc(frame_start);
    iters(nt) = iter;

    fprintf(['[' format_time(frame_time(nt)) '|' ...
            format_time(mean(frame_time(1:nt))*(TOTAL_STEPS-nt)) ...
            '-][#Broy steps: '  num2str(num_broydens_steps_required) ...
            '|Avg: '  num2str(round(running_total_count/nt,1))  ']'])

end

disp('')
disp('Run finished')
disp(['Total time:' format_time(sum(frame_time))])

if video
    close(Filament_movie);
end


function [concheck_local,ERROR_VECk1_local,VY] = F(X_S, Y_S, TX_S, TY_S,...
                                                   THETA_S, LAMBDA1,...
                                                   LAMBDA2, tol)
% F  places forces and torques on the segments, calculates the resultant
%    velocities and angular velocities, and forms the error vector f(X*).
%    Then checks convergence. For details, see docstrings of functions
%    within.

    FX = zeros(Np,1);
    FY = zeros(Np,1);
    TAUZ = zeros(Np,1);

    [TAUZ] = intrinsic_torques(TAUZ, KB, K, DL, omega, t + dt, T_0, SW_IND, PHASE);

    [TAUZ] = elastic_torques(TAUZ, TX_S, TY_S, KB, SW_IND, DL_SW);

    [FX, FY] = collision_barrier(X_S, Y_S, FX, FY, ...
                                 Lx_collision, Ly_collision, PtoS, ...
                                 map, head, list, RAD);

    [FX, FY, TAUZ] = constraint_forces_torques(FX, FY, TAUZ, TX_S, TY_S,...
                                         LAMBDA1, LAMBDA2, SW_IND, DL_SW);

    FZ = zeros(Np,1);
    TAUX = zeros(Np,1);
    TAUY = zeros(Np,1);
    Z_S = zeros(Np,1);
    [VX,VY,~,~,~,OMEGZ] = RPY(FX,FY,FZ,TAUX,TAUY,TAUZ,X_S,Y_S,Z_S,a,1);


    % Check convergence between x_(n+1) and x_n, and also check the
    % constraint. concheck = 0 if all fine, 1 otherwise. The error vectors
    % are all compiled into ERROR_VECk1_local.
    [concheck_local, ERROR_VECk1_local] = constraint_check_robot_arm(...
                                              X_S, Y_S, THETA_S, ...
                                              X, Y, THETA, ...
                                              X_T, Y_T, THETA_T, ...
                                              VX, VY, OMEGZ, ...
                                              DL, dt, nt, SW_IND, tol);
end

end
