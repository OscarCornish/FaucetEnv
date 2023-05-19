# sudo -E julia Test.jl

for i=1:256
    run(`bash Test $i`)
end
