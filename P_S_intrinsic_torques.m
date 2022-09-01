function [TAUZ] = intrinsic_torques(TAUZ_IN, KAP, K, DL, omega, t, T_0, SW_IND, PHASE)

TAUZ = TAUZ_IN;
N_w = size(SW_IND,2);
N_sw = size(SW_IND,1);

L= (N_w-1)*DL;

for i = 1
    %k = SW_IND(i,1);
    phi = PHASE(i);
    for j = 1:N_w-2
        s = DL*(j-1) + 0.5*DL;
        %phi = PHASE(i);
        if(s > 0.5*L)
            %fac = 1;
            %fac = 2.0*(s - 0.5*L)/(L);
            %fac = 4.0*s/(L);
            fac = 2.0*(L - s)/L;
        else
            %fac = 2.0*(L - s)/L;
            %fac = s/(0.7*L);
            fac = 1.0;
        end
        %fac=(erf((0.7-s/L)/0.2)+1.5)/(erf(0.7/0.2)+1.5);
        %fac = (erf((0.75-s/L)/0.25)+1)/(erf(0.75/0.25)+1);
        %fac = 1 - (s/L)^2;
        
        TAU_0 = T_0*KAP*fac*(sin(K*s - omega*t+phi));
        j_sw = SW_IND(i,j+1);
        j_swp1 = SW_IND(i,j+2);
        TAUZ(j_sw) = TAUZ(j_sw) + TAU_0;
        TAUZ(j_swp1) = TAUZ(j_swp1) - TAU_0;
    end
end

for i = 2
    %k = SW_IND(i,1);
    phi = PHASE(i)+pi;
    for j = 1:N_w-2
        s = DL*(j-1) + 0.5*DL;
        %phi = PHASE(i);
        if(s > 0.5*L)
            %fac = 1;
            %fac = 2.0*(s - 0.5*L)/(L);
            %fac = 4.0*s/(L);
            fac = 2.0*(L - s)/L;
        else
            %fac = 2.0*(L - s)/L;
            %fac = s/(0.7*L);
            fac = 1.0;
        end
        %fac=(erf((0.7-s/L)/0.2)+1.5)/(erf(0.7/0.2)+1.5);
        %fac = (erf((0.75-s/L)/0.25)+1)/(erf(0.75/0.25)+1);
        %fac = 1 - (s/L)^2;
        
        TAU_0 = T_0*KAP*fac*(sin(K*s - omega*t+phi));
        j_sw = SW_IND(i,j+1);
        j_swp1 = SW_IND(i,j+2);
        TAUZ(j_sw) = TAUZ(j_sw) + TAU_0;
        TAUZ(j_swp1) = TAUZ(j_swp1) - TAU_0;
    end
end

for i = 3
    %k = SW_IND(i,1);
    phi = PHASE(i);
    for j = 1:N_w-2
        s = DL*(j-1) + 0.5*DL;
        %phi = PHASE(i);
        if(s > 0.5*L)
            %fac = 1;
            %fac = 2.0*(s - 0.5*L)/(L);
            %fac = 4.0*s/(L);
            fac = 2.0*(L - s)/L;
        else
            %fac = 2.0*(L - s)/L;
            %fac = s/(0.7*L);
            fac = 1.0;
        end
        %fac=(erf((0.7-s/L)/0.2)+1.5)/(erf(0.7/0.2)+1.5);
        %fac = (erf((0.75-s/L)/0.25)+1)/(erf(0.75/0.25)+1);
        %fac = 1 - (s/L)^2;
        
        TAU_0 = T_0*KAP*fac*(sin(K*s - omega*t+phi));
        j_sw = SW_IND(i,j+1);
        j_swp1 = SW_IND(i,j+2);
        TAUZ(j_sw) = TAUZ(j_sw) + TAU_0;
        TAUZ(j_swp1) = TAUZ(j_swp1) - TAU_0;
    end
end