#define DEBUG

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/types.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/dma-buf.h>


#define DRIVER_NAME "custom-dma"

#define IRQ_BITMASK 0x3

struct custom_dma_regs {
	u32 trigger;
	u32 sdram_read_addr;
	u32 sdram_write_addr;
	u32 __unused0;
};

struct custom_dma_dev {
	struct platform_device *pdev;
    struct custom_dma_regs *regs;
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

// static irqreturn_t threaded_interrupt_handler(int irq, void* dev_id)
// {
// 	struct custom_dma_dev *dev = (struct custom_dma_dev *)dev_id;
// 	dev_dbg(&dev->pdev->dev, "IRQ: %d\n", irq);

// 	// Clear IRQ
// 	fpga_write32(IRQ_BITMASK, &dev->regs->irq_clear);
// 	fpga_read32(&dev->regs->state);

// 	return IRQ_HANDLED;
// }


// static irqreturn_t interrupt_handler(int irq, void* kobj)
// {
//    return IRQ_HANDLED;
// }


static int custom_dma_probe(struct platform_device *pdev)
{
	struct custom_dma_dev *dev;
	int rc = -EBUSY;
	// int irq;
	struct resource *r;

	size_t size = 4096;       // Size in bytes
	dma_addr_t phys_addr;     // The physical (bus) address
	void *virt_addr;          // The kernel virtual address
	dev_dbg(&pdev->dev, "dma_probe enter\n");

	r = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if(r == NULL) {
		dev_err(&pdev->dev, "IORESOURCE_MEM (register space) does not exist\n");
		goto bad_exit_return;
	}

	dev = devm_kzalloc(&pdev->dev, sizeof(struct custom_dma_dev), GFP_KERNEL);
	platform_set_drvdata(pdev, (void*)dev);

	dev->pdev = pdev;
	dev->regs = devm_ioremap_resource(&pdev->dev, r);

	if(IS_ERR(dev->regs)) {
		dev_err(&pdev->dev, "Failed to map regs\n");
		goto bad_exit_return;
	}

	virt_addr = dma_alloc_coherent(&pdev->dev, size, &phys_addr, GFP_KERNEL);
	if (!virt_addr) {
		dev_err(&pdev->dev, "Failed to map dma memory\n");
		goto bad_exit_return;
	}
	*(u32*)virt_addr = 0x6;
	wmb();

	fpga_write32(phys_addr, &dev->regs->sdram_read_addr);
	fpga_write32(1, &dev->regs->trigger);

#if 0
	irq = platform_get_irq(pdev, 0);
	if (irq < 0)
		goto bad_exit_return;

	// rc = devm_request_irq(&pdev->dev, irq, interrupt_handler, 0, "dma-irq", dev);

	rc = devm_request_threaded_irq(&pdev->dev, irq, NULL, threaded_interrupt_handler,
		IRQF_ONESHOT, "dma-irq", dev);

	if (rc) {
		dev_err(&pdev->dev, "Can't allocate irq %d\n", irq);
		goto bad_exit_return;
	}

	// Clear pending irqs (e.g. dma was pressed before probe)
	fpga_write32(IRQ_BITMASK, &dev->regs->irq_clear);

	// Enable irq mask
	fpga_write32(IRQ_BITMASK, &dev->regs->irq_mask);
#endif

	dev_dbg(&pdev->dev, "dma_probe exit\n");
	return 0;

bad_exit_return:
	dev_err(&pdev->dev, "dma_probe bad exit :(\n");
	return rc;
}

static int custom_dma_remove(struct platform_device *pdev)
{
	// struct custom_dma_dev *dev = 
	// 	(struct custom_dma_dev*)platform_get_drvdata(pdev);

	dev_dbg(&pdev->dev, "dma_remove enter\n");

	dev_dbg(&pdev->dev, "dma_remove exit\n");

	return 0;
}

// Specify which device tree devices this driver supports
static const struct of_device_id custom_dma_dt_ids[] = {
	{
		.compatible = "dev,custom-dma",
	},
	{ /* end of table */ }
};

// Inform the kernel about the devices this driver supports
MODULE_DEVICE_TABLE(of, custom_dma_dt_ids);

// Data structure that links the probe and remove functions with our driver
static struct platform_driver custom_dma = {
	.probe = custom_dma_probe,
	.remove = custom_dma_remove,
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table = custom_dma_dt_ids,
	}
};

module_platform_driver(custom_dma);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Dario Mylonopoulos");
MODULE_DESCRIPTION("A simple Linux driver for a custom dma device.");
MODULE_VERSION("1.0");
