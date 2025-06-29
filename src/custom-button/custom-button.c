#define DEBUG

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/types.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>


#define DRIVER_NAME "custom-button"

#define IRQ_BITMASK 0x3

struct custom_button_regs {
	u32 state;
	u32 __unused0;
	u32 irq_mask;
	u32 irq_clear;
};

struct custom_button_dev {
	struct platform_device *pdev;
    struct custom_button_regs *regs;
};

static inline u32 fpga_read32(const void __iomem *addr) {
	u32 value = ioread32(addr);
	pr_debug("%s(r): %p => %08x\n", DRIVER_NAME, addr, value);
	return value;
}

static inline void fpga_write32(u32 value, void __iomem *addr) {
	pr_debug("%s(w): %p <= %08x\n", DRIVER_NAME, addr, value);
	iowrite32(value, addr);
}

static irqreturn_t threaded_interrupt_handler(int irq, void* dev_id)
{
	struct custom_button_dev *dev = (struct custom_button_dev *)dev_id;
	dev_dbg(&dev->pdev->dev, "IRQ: %d\n", irq);

	// Clear IRQ
	fpga_write32(IRQ_BITMASK, &dev->regs->irq_clear);
	fpga_read32(&dev->regs->state);

	return IRQ_HANDLED;
}


// static irqreturn_t interrupt_handler(int irq, void* kobj)
// {
//    return IRQ_HANDLED;
// }


static int custom_button_probe(struct platform_device *pdev)
{
	struct custom_button_dev *dev;
	int rc = -EBUSY;
	int irq;
	struct resource *r;

	dev_dbg(&pdev->dev, "button_probe enter\n");

	r = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if(r == NULL) {
		dev_err(&pdev->dev, "IORESOURCE_MEM (register space) does not exist\n");
		goto bad_exit_return;
	}

	dev = devm_kzalloc(&pdev->dev, sizeof(struct custom_button_dev), GFP_KERNEL);
	platform_set_drvdata(pdev, (void*)dev);

	dev->pdev = pdev;
	dev->regs = devm_ioremap_resource(&pdev->dev, r);

	if(IS_ERR(dev->regs)) {
		dev_err(&pdev->dev, "Failed to map regs\n");
		goto bad_exit_return;
	}

	irq = platform_get_irq(pdev, 0);
	if (irq < 0)
		goto bad_exit_return;

	// rc = devm_request_irq(&pdev->dev, irq, interrupt_handler, 0, "button-irq", dev);

	rc = devm_request_threaded_irq(&pdev->dev, irq, NULL, threaded_interrupt_handler,
		IRQF_ONESHOT, "button-irq", dev);

	if (rc) {
		dev_err(&pdev->dev, "Can't allocate irq %d\n", irq);
		goto bad_exit_return;
	}

	// Clear pending irqs (e.g. button was pressed before probe)
	fpga_write32(IRQ_BITMASK, &dev->regs->irq_clear);

	// Enable irq mask
	fpga_write32(IRQ_BITMASK, &dev->regs->irq_mask);

	dev_dbg(&pdev->dev, "button_probe exit\n");
	return 0;

bad_exit_return:
	dev_err(&pdev->dev, "button_probe bad exit :(\n");
	return rc;
}

static int custom_button_remove(struct platform_device *pdev)
{
	// struct custom_button_dev *dev = 
	// 	(struct custom_button_dev*)platform_get_drvdata(pdev);

	dev_dbg(&pdev->dev, "button_remove enter\n");

	dev_dbg(&pdev->dev, "button_remove exit\n");

	return 0;
}

// Specify which device tree devices this driver supports
static const struct of_device_id custom_button_dt_ids[] = {
	{
		.compatible = "dev,custom-button",
	},
	{ /* end of table */ }
};

// Inform the kernel about the devices this driver supports
MODULE_DEVICE_TABLE(of, custom_button_dt_ids);

// Data structure that links the probe and remove functions with our driver
static struct platform_driver custom_button = {
	.probe = custom_button_probe,
	.remove = custom_button_remove,
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table = custom_button_dt_ids,
	}
};

module_platform_driver(custom_button);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Dario Mylonopoulos");
MODULE_DESCRIPTION("A simple Linux driver for a custom button device.");
MODULE_VERSION("1.0");
