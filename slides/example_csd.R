library(ggplot)
library(patchwork)
library(gsignal)

# create two timeseries with
# shared frequency component at 1/50 = 0.02
df.rois <- data.frame(
  t = seq(1,100),
  y1 = sin(2*3.14*t/50)+cos(2*3.14*t/20)+rnorm(100,0,0.5),
  y2 = sin(2*3.14*t/50)+cos(2*3.14*t/10)+rnorm(100,0,0.5)
)

# plot both timeseries in time domain
ggplot(df.rois) + 
  geom_line(aes(x = t, y = y1)) +  theme_bw() + labs(y = "y1", caption = "y1 = sin (0.02t * 2\u03C0) + cos (0.05t * 2\u03C0)") +
  
ggplot(as.data.frame(cpsd(matrix(cbind(df.rois$y1, df.rois$y1),100), window = 100)), aes(x = freq, y= X1.2))+
  geom_line() + theme_bw() + labs(y = "Power y1") + xlim(0,0.2) + 
  
ggplot(df.rois) + 
  geom_line(aes(x = t, y = y2), color = "red")+ theme_bw() + labs(y = "y2", caption = "y2 = sin (0.02t * 2\u03C0) + cos (0.1t * 2\u03C0)") +
  
ggplot(as.data.frame(cpsd(matrix(cbind(df.rois$y2, df.rois$y2),100), window = 100)), aes(x = freq, y= X1.2))+
  geom_line() + theme_bw() + labs(y = "Power y2") + xlim(0,0.2) +
  
ggplot(df.rois) + 
  geom_line(aes(x = t, y = y1)) + 
  geom_line(aes(x = t, y = y2), color = "red")+ theme_bw() + labs(y = "y1 & y2")  +


ggplot(as.data.frame(cpsd(matrix(cbind(df.rois$y1, df.rois$y2),100), window = 100)), aes(x = freq, y= X1.2))+
  geom_line() + theme_bw() + labs(y = "CSD") + xlim(0,0.2) + patchwork::plot_layout(ncol = 2)

