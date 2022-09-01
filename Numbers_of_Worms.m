global velocity_output
index = 1
min = 1;
max = 9;
step = 2;
Num_and_vel = zeros(2,((max-min)/step)+1);
for number = min:step:max
    run(number)
    Num_and_vel(1,index) = velocity_output(1,1);
    Num_and_vel(2,index) = velocity_output(2,1);
    index = index+1;
end
Num_and_vel
x = Num_and_vel(1,:);
y = Num_and_vel(2,:);
plot(x,y,'x-','LineWidth',3)

