function recpow(X, n)
	#%UNTITLED2 Summary of this function goes here
	#%   Detailed explanation goes here

	if round(n)!= n
	    error(string("The power has to be an integer", n,"\n"));
	end

	if n==Inf || isnan(n)
		Y = X.^n;    
		return Y
	end
	    
	if n==0
		Y = ones(size(X));
	else
		if n==1
			Y = X;
		else
			if mod(n,2) == 0
			Z = recpow(X, n/2);
			Y = Z .* Z;
			else
				Z = recpow(X, (n-1)/2);
				Y = Z .* Z .* X;
			end
		end
	end
	Y
end
