search_controller_json="<?php
namespace Beluga\Glossary\Controller\Index;

class SearchJson extends \Magento\Framework\App\Action\Action
{
    protected \$_itemFactory;
    protected \$_jsonResult;

    public function __construct(
        \Magento\Framework\App\Action\Context \$context,
        \Magento\Framework\Controller\Result\JsonFactory \$resultJsonFactory,
        \Beluga\Glossary\Model\ItemFactory \$itemFactory
    ) {
        \$this->_itemFactory = \$itemFactory;
        \$this->_jsonResult = \$resultJsonFactory;
        return parent::__construct(\$context);
    }

    public function execute()
    {
        \$search = \$this->getRequest()->getParam('search');
        \$result = \$this->_jsonResult->create();
        \$data = [];
        \$items = \$this->_itemFactory->
                        create()->
                        getCollection();
                        ->
                        addFieldToFilter(
                            'title', \$search
                        );
        
        foreach (\$items as \$item) {
            \$data[] = [
                \$item->getData()
            ];
        }

        return \$result->setData(\$data);
    }
}";
search_controller_html="<?php
namespace Beluga\Glossary\Controller\Index;

class Search extends \Magento\Framework\App\Action\Action
{
    protected \$_itemFactory;
    protected \$resultRawFactory;
    protected \$layoutFactory;

    public function __construct(
        \Magento\Framework\App\Action\Context \$context,
        \Magento\Framework\Controller\Result\RawFactory \$resultRawFactory,
        \Magento\Framework\View\LayoutFactory \$layoutFactory,
        \Beluga\Glossary\Model\ItemFactory \$itemFactory
    ) {
        \$this->_itemFactory = \$itemFactory;
        \$this->resultRawFactory = \$resultRawFactory;
        \$this->layoutFactory = \$layoutFactory;
        return parent::__construct(\$context);
    }

    public function execute()
    {
        \$search = \$this->getRequest()->getParam('search');
        \$result = \$this->_jsonResult->create();
        \$data = [];
        \$items = \$this->_glossaryFactory->
                        create()->
                        getCollection();
        \$select = \$items->getSelect();
        \$select->columns(new \Zend_Db_Expr('SUBSTR(title, 1, 1) AS first_letter'))
        ->order('first_letter', 'ASC');
        \$items = \$items->
        addFieldToFilter(
            ['title', 'description'],
            [['like' => '%' . \$search . '%'],['like' => '%' . \$search . '%']]
        );
        \$data = \$items->getItems();

        \$output = \$this->layoutFactory->create()
            ->createBlock('Beluga\Glossary\Block\Glossary', 'ajax.items.block', ['data'=>['items' => \$data]])
            ->toHtml();
        \$resultRaw = \$this->resultRawFactory->create();
        return \$resultRaw->setContents(\$output);
    }
}"