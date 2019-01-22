
struct IndexSet
    inds::Vector{Index}
    IndexSet(inds::Vector{Index}) = new(inds)
    IndexSet(inds::Index...) = new([inds...])
end

getindex(is::IndexSet,n::Integer) = getindex(is.inds,n)
setindex!(is::IndexSet,n::Integer) = setindex!(is.inds,n)
length(is::IndexSet) = length(is.inds)
rank(is::IndexSet) = length(is)
order(is::IndexSet) = length(is)
copy(is::IndexSet) = IndexSet(copy(is.inds))
dims(is::IndexSet) = Tuple(dim(i) for i in is)
dim(is::IndexSet) = prod(dims(is))

dag(is::IndexSet) = IndexSet(dag.(is.inds))

# Allow iteration
size(is::IndexSet) = size(is.inds)
iterate(is::IndexSet,state=1) = iterate(is.inds,state)

push!(is::IndexSet,i::Index) = push!(is.inds,i)

function prime(is::IndexSet,plinc::Integer=1)
  res = copy(is)
  res.inds .= prime.(res,plinc)
  return res
end

function calculate_permutation(set1,set2)
  l1 = length(set1)
  l2 = length(set2)
  l1==l2 || error("Mismatched input sizes in calcPerm")
  p = zeros(Int,l1)
  for i1 = 1:l1
    for i2 = 1:l2
      if set1[i1]==set2[i2]
        p[i1] = i2
        break
      end
    end #i2
    p[i1]!=0 || error("Sets aren't permutations of each other")
  end #i1
  return p
end

function compute_contraction_labels(Ai::IndexSet,Bi::IndexSet)
  rA = order(Ai)
  rB = order(Bi)
  Aind = zeros(Int,rA)
  Bind = zeros(Int,rB)

  ncont = 0
  for i = 1:rA, j = 1:rB
    if Ai[i]==Bi[j]
      Aind[i] = Bind[j] = -(1+ncont)
      ncont += 1
    end
  end

  u = ncont
  for i = 1:rA
    if(Aind[i]==0) Aind[i] = (u+=1) end
  end
  for j = 1:rB
    if(Bind[j]==0) Bind[j] = (u+=1) end
  end

  return (Aind,Bind)
end

function contract_inds(Ais::IndexSet,Aind,
                       Bis::IndexSet,Bind)
  ncont = 0
  for i in Aind
    if(i < 0) ncont += 1 end 
  end
  nuniq = rank(Ais)+rank(Bis)-2*ncont
  Cind = zeros(Int,nuniq)
  Cis = fill(Index(),nuniq)
  u = 1
  for i = 1:rank(Ais)
    if(Aind[i] > 0) 
      Cind[u] = Aind[i]; 
      Cis[u] = Ais[i]; 
      u += 1 
    end
  end
  for i = 1:rank(Bis)
    if(Bind[i] > 0) 
      Cind[u] = Bind[i]; 
      Cis[u] = Bis[i]; 
      u += 1 
    end
  end
  return (IndexSet(Cis...),Cind)
end

function compute_strides(inds::IndexSet)
  r = order(inds)
  stride = zeros(Int, r)
  s = 1
  for i = 1:r
    stride[i] = s
    s *= dim(inds[i])
  end
  return stride
end
