class LineReferentialDecorator < AF83::Decorator
  decorates LineReferential
  set_scope { [context[:workbench]] }
end
