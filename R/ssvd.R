## Implementation of the sparse SVD
#
#	work with thresh.R 
#
#  	Input variables:
#       X - argument (n x d matrix)
#       threu = type of penalty (thresholding rule) for the left 
#       	    singular vector,
#			1 = (Adaptive) LASSO (default)
#                 2 = hard thresholding
#                 3 = SCAD
#
#       threv = type of penalty (thresholding rule) for the right 
#               singular vector,
#                 1 = (Adaptive) LASSO (default)
#                 2 = hard thresholding
#                 3 = SCAD
#
#       gamu = weight parameter in Adaptive LASSO for the 
#              left singular vector, nonnegative constant (default = 0, LASSO)
#
#       gamv = weight parameter in Adaptive LASSO for the  
#              right singular vector, nonnegative constant (default = 0, LASSO)
#
#       u0,  v0 = initial values of left/right singular vectors                
#                 (default = the classical SVs)
# 
#       merr = threshold to decide convergence (default = 10^(-4))
#
#       niter = maximum number of iterations (default = 100)
#
#   Output: 
#       u = left sparse singular vector
#       v = right sparse singaulr vector
#       iter = number of iterations to achieve the convergence


ssvd = function(X,threu = 1, threv = 1, gamu = 0, gamv =0,  u0 = svd(X)$u[,1], v0 = svd(X)$v[,1], merr = 10^(-4), niter = 100){
    n = dim(X)[1]
    d = dim(X)[2]

    ud = 1;
    vd = 1;
    iter = 0;
    SST = sum(X^2);

    while (ud > merr || vd > merr) {
        iter = iter+1;
		cat("iter: ",iter,"\n")
		cat("v: ",length(which(v0!=0)),"\n")
		cat("u: ",length(which(u0!=0)),"\n")
        # Updating v
        z =  t(X)%*% u0;
        winv = abs(z)^gamv;
        sigsq = abs(SST - sum(z^2))/(n*d-d);

        tv = sort(c(0, abs(z*winv)));
        rv = sum(tv>0);
        Bv = rep(1,d+1)*Inf;
    
        for (i in 1:rv){
            lvc  =  tv[d+1-i];
            temp1 = which(winv!=0);
            
            temp2 = thresh(z[temp1], type = threv, delta = lvc/winv[temp1]);
            vc = rep(0,d)
            vc[temp1] = temp2;
            Bv[i] = sum((X - u0%*%t(vc))^2)/sigsq + i*log(n*d)
        }
    
        Iv = min(which(Bv==min(Bv)))
        temp = sort(c(0, abs(z*winv)));        lv = temp[d+1-Iv]
    
        temp2 = thresh(z[temp1],type = threv, delta = lv/winv[temp1]);
        v1 = rep(0,d)
        v1[temp1] = temp2;
        v1 = v1/sqrt(sum(v1^2)) #v_new
	
		cat("v1", length(which(v1!=0)) ,"\n" )
		#str(X)
		#str(v1)
        # Updating u
        z = X%*%v1;
        winu = abs(z)^gamu;
        sigsq = abs(SST - sum(z^2))/(n*d-n)

        tu = sort(c(0,abs(z*winu)));
        ru = sum(tu>0);
        Bu = rep(1,n+1)*Inf;

        for (i in 1:ru){
            luc  =  tu[n+1-i];
            temp1 = which(winu!=0);
            temp2 = thresh(z[temp1], type = threu, delta = luc/winu[temp1]);
            uc = rep(0,n)
            uc[temp1] = temp2;
            Bu[i] = sum((X - uc%*%t(v1))^2)/sigsq + i*log(n*d)
        }
        
        Iu = min(which(Bu==min(Bu)));
        temp = sort(c(0, abs(z*winu)))
        lu = temp[n+1-Iu];
	  temp2 = thresh(z[temp1],delta = lu/winu[temp1]);
        u1 = rep(0,n);
        u1[temp1] = temp2;
        u1 = u1/sqrt(sum(u1^2));

    
        ud = sqrt(sum((u0-u1)^2));
        vd = sqrt(sum((v0-v1)^2));

        if (iter > niter){
        print("Fail to converge! Increase the niter!")
	  break
        }
        
	u0 = u1;
	v0 = v1;
    }

return(list(u = u1, v = v1, iter = iter))
}