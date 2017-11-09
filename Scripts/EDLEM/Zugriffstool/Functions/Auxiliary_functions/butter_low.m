function [num, den] = butter_low(n, Wn)
%BUTTER_LOW    Parameter für Tiefpassfilter n-ter Ordnung 
%   Erstellt Parameter für einen Tiefpassfilter n-ter Ordnung. In Anlehnung an die
%   Funktion BUTTER der Signal-Processing-Toolbox.

% Franz Zeilinger - 23.01.2012

if n>500
	return;
end

fs = 2;
u = 2*fs*tan(pi*Wn/fs);
Wn = u;
z = [];
p = exp(1i*(pi*(1:2:n-1)/(2*n) + pi/2));
p = [p; conj(p)];
p = p(:);

if rem(n,2)==1  
    p = [p; -1];
end

p = p(isfinite(p));
z = z(isfinite(z));
np = length(p);
nz = length(z);
try
    z = cplxpair(z,0);
    p = cplxpair(p,0);
catch %#ok<CTCH>
    z = cplxpair(z,1e6*nz*norm(z)*eps + eps);
    p = cplxpair(p,1e6*np*norm(p)*eps + eps);
end

a=[]; b=zeros(0,1); c=ones(1,0); d=1;
if rem(np,2) && rem(nz,2)
    a = p(np);
    b = 1;
    c = p(np) - z(nz);
    d = 1;
    np = np - 1;
    nz = nz - 1;
end
if rem(np,2)
    a = p(np);
    b = 1;
    c = 1;
    d = 0;
    np = np - 1;
end 
if rem(nz,2)
    num = real(poly(z(nz)));
    den = real(poly(p(np-1:np)));
    wn = sqrt(prod(abs(p(np-1:np))));
    if wn == 0, wn = 1; end
    t = diag([1 1/wn]);
    a = t\[-den(2) -den(3); 1 0]*t;
    b = t\[1; 0];
    c = [1 num(2)]*t;
    d = 0;
    nz = nz - 1;
    np = np - 2;
end
i = 1;
while i < nz
    index = i:i+1;
    num = real(poly(z(index)));
    den = real(poly(p(index)));
    wn = sqrt(prod(abs(p(index))));
    if wn == 0, wn = 1; end
    t = diag([1 1/wn]);
    a1 = t\[-den(2) -den(3); 1 0]*t;
    b1 = t\[1; 0];
    c1 = [num(2)-den(2) num(3)-den(3)]*t;
    d1 = 1;
    ma1 = size(a,1);
    na2 = size(a1,2);
    a = [a zeros(ma1,na2); b1*c a1]; %#ok<AGROW>
    b = [b; b1*d]; %#ok<AGROW>
    c = [d1*c c1];
    d = d1*d;
    i = i + 2;
end
while i < np
    den = real(poly(p(i:i+1)));
    wn = sqrt(prod(abs(p(i:i+1))));
    if wn == 0, wn = 1; end
    t = diag([1 1/wn]);
    a1 = t\[-den(2) -den(3); 1 0]*t;
    b1 = t\[1; 0];
    c1 = [0 1]*t;
    d1 = 0;
    ma1 = size(a,1);
    na2 = size(a1,2);
    a = [a zeros(ma1,na2); b1*c a1]; %#ok<AGROW>
    b = [b; b1*d]; %#ok<AGROW>
    c = [d1*c c1];
    d = d1*d;
    i = i + 2;
end

a = Wn*a;
t = 1/fs;
t1 = eye(size(a)) + a*t/2;
t2 = eye(size(a)) - a*t/2;
a = t2\t1;
den = poly(a);

r = -ones(n,1);
w = 0;
b = poly(r);
kern = exp(-1j*w*(0:length(b)-1));
num = real(b*(kern*den(:))/(kern*b(:)));