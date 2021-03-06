function wtrans=sincsq3d(ifl,a1,a2,a3,klocs_d1,klocs_d2,klocs_d3,q,tol,mode)

if(nargin<1), test_sincsq3d; return; end

%  
% wtrans(j) = sum sinc^2(a1(k)-klocs_d1(j)) * sinc^2(a2(k)-klocs_d2(j)) * sinc^2(a3(k)-klocs_d3(j)) * q(j)
%              k
%
% ifl = sinc convention
%   0: sinc(x) = sin(x)/x
%   1: sinc(x)=sin(pi*x)/(pi*x)
% a1 = (real) evaluation locations in dimension 1
% a2 = (real) evaluation locations in dimension 2
% a3 = (real) evaluation locations in dimension 3
% klocs_d1 = (real) sample locations in dimension 1
% klocs_d2 = (real) sample locations in dimension 2
% klocs_d3 = (real) sample locations in dimension 3
% q = sample strengths
% tol = requested precision

newtol=max(tol/1000,1e-16);

rkmaxx=max(bsxfun(@max,zeros(size(klocs_d1)),abs(klocs_d1)));
rkmaxx=max(rkmaxx,max(bsxfun(@max,zeros(size(a1)),abs(a1))));
rkmaxy=max(bsxfun(@max,zeros(size(klocs_d2)),abs(klocs_d2)));
rkmaxy=max(rkmaxy,max(bsxfun(@max,zeros(size(a2)),abs(a2))));
rkmaxz=max(bsxfun(@max,zeros(size(klocs_d3)),abs(klocs_d3)));
rkmaxz=max(rkmaxz,max(bsxfun(@max,zeros(size(a3)),abs(a3))));

if ifl==1
    rkmaxx=pi*rkmaxx;
    rkmaxy=pi*rkmaxy;
    rkmaxz=pi*rkmaxz;
    klocs_d1=pi*klocs_d1;
    klocs_d2=pi*klocs_d2;
    klocs_d3=pi*klocs_d3;
    a1=pi*a1;
    a2=pi*a2;
    a3=pi*a3;
end
rsamp=2; % increase to impose higher accuracy; will increase runtime
nx=ceil(rsamp*round(rkmaxx+3)); 
ny=ceil(rsamp*round(rkmaxy+3));
nz=ceil(rsamp*round(rkmaxz+3));

if isequal(mode,'legendre')
[xx,wwx]=lgwt(nx,-1,1);
[yy,wwy]=lgwt(ny,-1,1);
[zz,wwz]=lgwt(nz,-1,1);
xx=vertcat(xx-1,xx+1);
wwx=vertcat(wwx,wwx);
wwx=wwx.*(2-abs(xx));
yy=vertcat(yy-1,yy+1);
wwy=vertcat(wwy,wwy);
wwy=wwy.*(2-abs(yy));
zz=vertcat(zz-1,zz+1);
wwz=vertcat(wwz,wwz);
wwz=wwz.*(2-abs(zz));
[c,d,e]=ndgrid(xx,yy,zz);
allxx=c(:);
allyy=d(:);
allzz=e(:);
[f,g,h]=ndgrid(wwx,wwy,wwz);
allww=f(:).*g(:).*h(:);
h_at_xxyyzz=finufft3d3(klocs_d1,klocs_d2,klocs_d3,q,-1,newtol,allxx,allyy,allzz);
wtrans=(1/64)*finufft3d3(allxx,allyy,allzz,h_at_xxyyzz.*allww,1,newtol,klocs_d1,klocs_d2,klocs_d3);  
else

a=-2; b=0;
e=21; % increase (up to 60) to impose higher accuracy; will increase runtime
if mod(nx,2)~=0; nx=nx+1; end % ensure even so that 0 is a quadrature point
n=nx; h=(b-a)/n;
xx=a-(e*h):h:b+(n+e)*h; xx=xx(:);
aind=e+1; zind=aind+n; bind=zind+n; 

leftvec=zeros(size(xx));
rightvec=zeros(size(xx));
trianglevec=zeros(size(xx));
for i=1:length(leftvec)
    val=xx(i);
    leftvec(i)=2+val;
    rightvec(i)=2-val;
    trianglevec(i)=2-abs(val);
end

load('newconstants.mat')
constants=constantcell{e};

ww_trap=zeros(size(xx));
ww_trap(aind)=0.5; ww_trap(bind)=0.5;
ww_trap(aind+1:bind-1)=1; %includes 0: 0.5 and 0.5 from left and right add
ww_trap(aind:bind)=ww_trap(aind:bind).*trianglevec(aind:bind); 
ww_left=zeros(size(xx)); %corrections from left side
ww_right=zeros(size(xx)); %corrections from right side
for k=1:e
    ww_left(aind-k) = ww_left(aind-k) - leftvec(aind-k)*constants(k);
    ww_left(aind+k) = ww_left(aind+k) + leftvec(aind+k)*constants(k);
    ww_left(zind-k) = ww_left(zind-k) + leftvec(zind-k)*constants(k);
    ww_left(zind+k) = ww_left(zind+k) - leftvec(zind+k)*constants(k);
end
for k=1:e
    ww_right(zind-k) =  ww_right(zind-k)- rightvec(zind-k)*constants(k);
    ww_right(zind+k) =  ww_right(zind+k)+ rightvec(zind+k)*constants(k);
    ww_right(bind-k) =  ww_right(bind-k)+ rightvec(bind-k)*constants(k);
    ww_right(bind+k) =  ww_right(bind+k)- rightvec(bind+k)*constants(k);
end
ww=ww_trap+ww_left+ww_right; 
wwx=h*ww;

if mod(ny,2)~=0; ny=ny+1; end % ensure even so that 0 is a quadrature point
n=ny; h=(b-a)/n;
yy=a-(e*h):h:b+(n+e)*h; yy=yy(:);
aind=e+1; zind=aind+n; bind=zind+n; 

leftvec=zeros(size(yy));
rightvec=zeros(size(yy));
trianglevec=zeros(size(yy));
for i=1:length(leftvec)
    val=yy(i);
    leftvec(i)=2+val;
    rightvec(i)=2-val;
    trianglevec(i)=2-abs(val);
end

ww_trap=zeros(size(yy));
ww_trap(aind)=0.5; ww_trap(bind)=0.5;
ww_trap(aind+1:bind-1)=1; %includes 0: 0.5 and 0.5 from left and right add
ww_trap(aind:bind)=ww_trap(aind:bind).*trianglevec(aind:bind); 
ww_left=zeros(size(yy)); %corrections from left side
ww_right=zeros(size(yy)); %corrections from right side
for k=1:e
    ww_left(aind-k) = ww_left(aind-k) - leftvec(aind-k)*constants(k);
    ww_left(aind+k) = ww_left(aind+k) + leftvec(aind+k)*constants(k);
    ww_left(zind-k) = ww_left(zind-k) + leftvec(zind-k)*constants(k);
    ww_left(zind+k) = ww_left(zind+k) - leftvec(zind+k)*constants(k);
end
for k=1:e
    ww_right(zind-k) =  ww_right(zind-k)- rightvec(zind-k)*constants(k);
    ww_right(zind+k) =  ww_right(zind+k)+ rightvec(zind+k)*constants(k);
    ww_right(bind-k) =  ww_right(bind-k)+ rightvec(bind-k)*constants(k);
    ww_right(bind+k) =  ww_right(bind+k)- rightvec(bind+k)*constants(k);
end
ww=ww_trap+ww_left+ww_right; % ADD BACK IN to use corrections
wwy=h*ww;

if mod(nz,2)~=0; nz=nz+1; end % ensure even so that 0 is a quadrature point
n=nz; h=(b-a)/n;
zz=a-(e*h):h:b+(n+e)*h; zz=zz(:);
aind=e+1; zind=aind+n; bind=zind+n; 

leftvec=zeros(size(zz));
rightvec=zeros(size(zz));
trianglevec=zeros(size(zz));
for i=1:length(leftvec)
    val=zz(i);
    leftvec(i)=2+val;
    rightvec(i)=2-val;
    trianglevec(i)=2-abs(val);
end

ww_trap=zeros(size(zz));
ww_trap(aind)=0.5; ww_trap(bind)=0.5;
ww_trap(aind+1:bind-1)=1; %includes 0: 0.5 and 0.5 from left and right add
ww_trap(aind:bind)=ww_trap(aind:bind).*trianglevec(aind:bind); 
ww_left=zeros(size(zz)); %corrections from left side
ww_right=zeros(size(zz)); %corrections from right side
for k=1:e
    ww_left(aind-k) = ww_left(aind-k) - leftvec(aind-k)*constants(k);
    ww_left(aind+k) = ww_left(aind+k) + leftvec(aind+k)*constants(k);
    ww_left(zind-k) = ww_left(zind-k) + leftvec(zind-k)*constants(k);
    ww_left(zind+k) = ww_left(zind+k) - leftvec(zind+k)*constants(k);
end
for k=1:e
    ww_right(zind-k) =  ww_right(zind-k)- rightvec(zind-k)*constants(k);
    ww_right(zind+k) =  ww_right(zind+k)+ rightvec(zind+k)*constants(k);
    ww_right(bind-k) =  ww_right(bind-k)+ rightvec(bind-k)*constants(k);
    ww_right(bind+k) =  ww_right(bind+k)- rightvec(bind+k)*constants(k);
end
ww=ww_trap+ww_left+ww_right; % ADD BACK IN to use corrections
wwz=h*ww;

[f,g,h]=ndgrid(wwx,wwy,wwz);
allww=f(:).*g(:).*h(:);

msx=length(xx); msy=length(yy); msz=length(zz);
actual_unif_spacex=xx(2)-xx(1);
actual_unif_spacey=yy(2)-yy(1);
actual_unif_spacez=zz(2)-zz(1);
if max(abs(klocs_d1))*actual_unif_spacex>pi || max(abs(a1))*actual_unif_spacex>pi || max(abs(klocs_d2))*actual_unif_spacey>pi || max(abs(a2))*actual_unif_spacey>pi || max(abs(klocs_d3))*actual_unif_spacey>pi || max(abs(a3))*actual_unif_spacey>pi
    fprintf('Error: cannot use finufft type 1/2 here; outside [-pi,pi]\n');
end
Lx=xx(1); Ly=yy(1); Lz=zz(1);
if mod(msx,2)==0
    DU1x=-msx/2;
else
    DU1x=(-msx+1)/2;
end
if mod(msy,2)==0
    DU1y=-msy/2;
else
    DU1y=(-msy+1)/2;
end
if mod(msz,2)==0
    DU1z=-msz/2;
else
    DU1z=(-msz+1)/2;
end
translationx=(DU1x-(Lx/actual_unif_spacex));
translationy=(DU1y-(Ly/actual_unif_spacey));
translationz=(DU1z-(Lz/actual_unif_spacez));

h_at_xxyyzz=finufft3d1(klocs_d1*actual_unif_spacex,klocs_d2*actual_unif_spacey,klocs_d3*actual_unif_spacez,q.'.*exp(1i*((actual_unif_spacex*klocs_d1*translationx) + (actual_unif_spacey*klocs_d2*translationy) + (actual_unif_spacez*klocs_d3*translationz))),-1,newtol,msx,msy,msz);
h_at_xxyyzz=h_at_xxyyzz(:);

translationx=((-1*DU1x)*actual_unif_spacex)+Lx;
translationy=((-1*DU1y)*actual_unif_spacey)+Ly;
translationz=((-1*DU1z)*actual_unif_spacez)+Lz;
temp=finufft3d2(a1*actual_unif_spacex,a2*actual_unif_spacey,a3*actual_unif_spacez,1,newtol,reshape(h_at_xxyyzz.*allww,msx,msy,msz));
wtrans=(1/64)*exp(1i*(translationx*a1+translationy*a2+translationz*a3)).*temp;
end

% For real inputs, only return real values. Otherwise, return complex
% wtrans
if isreal(q)
    wtrans=real(wtrans);
end
end

function test_sincsq3d
n=10; ifl=0;
klocs_d1=-pi+(2*pi*rand(n,1));
klocs_d2=-pi+(2*pi*rand(n,1));
klocs_d3=-pi+(2*pi*rand(n,1));
a1=rand(n,1);
a2=rand(n,1);
a3=-pi+(2*pi*rand(n,1));
q=complex(rand(1,n)*30,rand(1,n)*30);
tic;correct=slowsincsq3d(ifl,a1,a2,a3,klocs_d1,klocs_d2,klocs_d3,q);t3=toc;
precisions=[1e-2 1e-3 1e-4 1e-5 1e-6 1e-7 1e-8 1e-9 1e-10 1e-11 1e-12 1e-13 1e-14 1e-15];
for p=1:length(precisions)
    pr=precisions(p);
    tic;myresult=sincsq3d(ifl,a1,a2,a3,klocs_d1,klocs_d2,klocs_d3,q,pr,'legendre');t1=toc;
    tic;myresult2=sincsq3d(ifl,a1,a2,a3,klocs_d1,klocs_d2,klocs_d3,q,pr,'trap');t2=toc;
    err1=norm(correct-myresult,2);
    err2=norm(correct-myresult2,2);
    fprintf("Requested: %g Error (Leg): %g (Trap): %g\n", pr, err1,err2);
    fprintf("              Time  (Leg): %g s (Trap): %g s (Direct): %g s\n",t1,t2,t3);

end
end

function correct=superslowsincsq3d(ifl,a1,a2,a3,klocs_d1,klocs_d2,klocs_d3,q) 
% Alternative brute force calculation; even slower
% May be substituted in timing tests 
    results=zeros(size(a1)); 
    for ind=1:length(results)
        sm=0;
        for j=1:length(klocs_d1)
            if ifl==0
                val=q(j)*(sinc(a1(ind)-klocs_d1(j))^2)*(sinc(a2(ind)-klocs_d2(j))^2)*(sinc(a3(ind)-klocs_d3(j))^2);
            else
                val=q(j)*(sinc(pi*(a1(ind)-klocs_d1(j)))^2)*(sinc(pi*(a2(ind)-klocs_d2(j)))^2)*(sinc(pi*(a3(ind)-klocs_d3(j)))^2);
            end
            sm=sm+val;
        end
        results(ind)=sm;
    end
    correct=results;
end

function val=sinc(x)
    if x==0
        val=1;
    else
        val=sin(x)/x;
    end
end

function correct=slowsincsq3d(ifl,a1,a2,a3,klocs_d1,klocs_d2,klocs_d3,q)
    [a1,b1]=ndgrid(a1,klocs_d1);
    [a2,b2]=ndgrid(a2,klocs_d2);
    [a3,b3]=ndgrid(a3,klocs_d3);
    if ifl==1
        x=sin(pi*(a1-b1))./(pi*(a1-b1));
        y=sin(pi*(a2-b2))./(pi*(a2-b2));
        z=sin(pi*(a3-b3))./(pi*(a3-b3));
    else
        x=sin(a1-b1)./(a1-b1);
        y=sin(a2-b2)./(a2-b2);
        z=sin(a3-b3)./(a3-b3);
    end
    x(arrayfun(@isnan,x))=1;
    y(arrayfun(@isnan,y))=1;
    z(arrayfun(@isnan,z))=1;
    sincmat=x.*y.*z;
    sincmat=sincmat.^2;
    correct=sum(repmat(q,length(klocs_d1),1).*sincmat,2); % column vector
end